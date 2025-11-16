#!/usr/bin/env bash
set -euo pipefail

# AlphaOS license validation helper
# Fetches the Shopify-hosted entitlement URL, validates the payload, and enforces
# a grace policy to keep kiosks online during transient outages.

PATH=/usr/sbin:/usr/bin:/sbin:/bin
STATE_DIR="/var/lib/alphaos"
STATE_FILE="$STATE_DIR/license-state.json"
RUNTIME_STATUS="/run/alphaos/license-status"
LICENSE_URL_FILE="/etc/alphaos/license-url"
EXPECTED_HASH_FILE="/etc/alphaos/license-expected-sha256"
GRACE_LIMIT="${GRACE_LIMIT:-16}"          # 16 * 15m timer interval ≈ 4 hours
LICENSE_USER="${LICENSE_USER:-alphaos-licd}"
TMP_PAYLOAD="$(mktemp)"
trap 'rm -f "$TMP_PAYLOAD"' EXIT

log() {
  local level="$1"; shift
  local message="$*"
  if command -v systemd-cat >/dev/null 2>&1; then
    printf '%s\n' "$message" | systemd-cat --identifier=alphaos-license-check --priority="$level"
  else
    logger -t alphaos-license-check -p "user.$level" -- "$message"
  fi
}

ensure_paths() {
  install -d -m 0750 -o "$LICENSE_USER" -g "$LICENSE_USER" "$STATE_DIR"
  install -d -m 0770 -o "$LICENSE_USER" -g "$LICENSE_USER" "$(dirname "$RUNTIME_STATUS")"
}

read_state() {
  if [[ -f "$STATE_FILE" ]]; then
    if command -v jq >/dev/null 2>&1; then
      jq -r '.consecutive_failures' "$STATE_FILE" 2>/dev/null || echo 0
    else
      grep -o '"consecutive_failures":[^,]*' "$STATE_FILE" | awk -F: '{print $2}' 2>/dev/null || echo 0
    fi
  else
    echo 0
  fi
}

write_state() {
  local status="$1"
  local message="$2"
  local failures="$3"
  local payload_hash="$4"
  local now
  now="$(date --iso-8601=seconds)"
  cat >"$STATE_FILE.tmp" <<JSON
{
  "last_run": "$now",
  "status": "$status",
  "message": "$message",
  "payload_sha256": "$payload_hash",
  "consecutive_failures": $failures
}
JSON
  chown "$LICENSE_USER:$LICENSE_USER" "$STATE_FILE.tmp"
  chmod 0640 "$STATE_FILE.tmp"
  mv "$STATE_FILE.tmp" "$STATE_FILE"
  printf '%s|%s|%s|%s' "$status" "$message" "$now" "$failures" > "$RUNTIME_STATUS.tmp"
  chmod 0660 "$RUNTIME_STATUS.tmp"
  chown "$LICENSE_USER:$LICENSE_USER" "$RUNTIME_STATUS.tmp"
  mv "$RUNTIME_STATUS.tmp" "$RUNTIME_STATUS"
}

fail() {
  local reason="$1"
  local failures="$2"
  write_state "FAIL" "$reason" "$failures" ""
  log err "License check failed: $reason (failure $failures/$GRACE_LIMIT)"
  if (( failures >= GRACE_LIMIT )); then
    log err "Grace window exhausted – signaling kiosk shutdown requirement."
    exit 2
  fi
  exit 1
}

main() {
  ensure_paths

  if [[ ! -s "$LICENSE_URL_FILE" ]]; then
    log err "License URL file missing or empty ($LICENSE_URL_FILE)"
    fail "missing-license-url" "$(($(read_state)+1))"
  fi
  local license_url
  license_url="$(tr -d '\r' <"$LICENSE_URL_FILE" | sed -n '1p')"

  local consecutive_failures
  consecutive_failures="$(read_state)"

  if ! command -v curl >/dev/null 2>&1; then
    fail "curl-not-available" "$((consecutive_failures + 1))"
  fi

  local curl_exit=0
  local response_headers
  response_headers="$(curl \
    --silent --show-error --location --fail \
    --max-time 15 --connect-timeout 5 \
    --proto '=https' --tlsv1.2 \
    --retry 2 --retry-delay 2 \
    --output "$TMP_PAYLOAD" \
    --write-out '%{http_code}' \
    "$license_url")" || curl_exit=$?

  if (( curl_exit != 0 )); then
    fail "curl-error-$curl_exit" "$((consecutive_failures + 1))"
  fi

  local payload_hash
  payload_hash="$(sha256sum "$TMP_PAYLOAD" | awk '{print $1}')"

  if [[ -s "$EXPECTED_HASH_FILE" ]]; then
    local expected_hash
    expected_hash="$(tr -d '[:space:]' <"$EXPECTED_HASH_FILE")"
    if [[ "$payload_hash" != "$expected_hash" ]]; then
      fail "hash-mismatch" "$((consecutive_failures + 1))"
    fi
  fi

  local body
  body="$(head -c 2048 "$TMP_PAYLOAD" | tr -d '\0')"
  if [[ -z "$body" ]]; then
    fail "empty-payload" "$((consecutive_failures + 1))"
  fi

  # Successful validation – reset counters and log summary
  write_state "OK" "http:$response_headers" 0 "$payload_hash"
  log info "License verified (hash=$payload_hash, http=$response_headers)"
}

main "$@"
