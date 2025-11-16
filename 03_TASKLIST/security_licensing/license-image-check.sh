#!/usr/bin/env bash
set -euo pipefail

# AlphaOS license image availability probe.
# Confirms the canonical Shopify asset is reachable and still an image.

PATH=/usr/sbin:/usr/bin:/sbin:/bin
STATE_DIR="/var/lib/alphaos"
STATE_FILE="$STATE_DIR/license-image-state.json"
LICENSE_URL_FILE="/etc/alphaos/license-url"
LICENSE_USER="${LICENSE_USER:-alphaos-licd}"
TMP_HEADERS="$(mktemp)"
trap 'rm -f "$TMP_HEADERS"' EXIT

log() {
  local level="$1"; shift
  local message="$*"
  if command -v systemd-cat >/dev/null 2>&1; then
    printf '%s\n' "$message" | systemd-cat --identifier=alphaos-license-image-check --priority="$level"
  else
    logger -t alphaos-license-image-check -p "user.$level" -- "$message"
  fi
}

write_state() {
  local status="$1"
  local message="$2"
  local now
  now="$(date --iso-8601=seconds)"
  cat >"$STATE_FILE.tmp" <<JSON
{
  "last_run": "$now",
  "status": "$status",
  "message": "$message"
}
JSON
  chown "$LICENSE_USER:$LICENSE_USER" "$STATE_FILE.tmp"
  chmod 0640 "$STATE_FILE.tmp"
  mv "$STATE_FILE.tmp" "$STATE_FILE"
}

fail() {
  local reason="$1"
  write_state "FAIL" "$reason"
  log err "License image probe failed: $reason"
  exit 1
}

main() {
  install -d -m 0750 -o "$LICENSE_USER" -g "$LICENSE_USER" "$STATE_DIR"

  if [[ ! -s "$LICENSE_URL_FILE" ]]; then
    fail "missing-license-url"
  fi
  local license_url
  license_url="$(tr -d '\r' <"$LICENSE_URL_FILE" | sed -n '1p')"

  local curl_exit=0
  curl --silent --show-error --location --fail --head \
    --max-time 20 --connect-timeout 5 \
    --proto '=https' --tlsv1.2 \
    --output "$TMP_HEADERS" \
    "$license_url" || curl_exit=$?

  if (( curl_exit != 0 )); then
    fail "curl-error-$curl_exit"
  fi

  local http_code
  http_code="$(grep -m1 -i '^HTTP/' "$TMP_HEADERS" | awk '{print $2}')"
  local content_type
  content_type="$(sed -n 's/^Content-Type:[[:space:]]*//Ip' "$TMP_HEADERS" | head -n1 | tr '[:upper:]' '[:lower:]' | tr -d '\r')"

  if [[ "$http_code" != "200" ]]; then
    fail "http-$http_code"
  fi
  if [[ $content_type != image/* ]]; then
    fail "unexpected-content-type:${content_type:-unknown}"
  fi

  write_state "OK" "http:$http_code ct:$content_type"
  log info "License image reachable (http=$http_code, content-type=$content_type)"
}

main "$@"
