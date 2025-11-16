#!/usr/bin/env bash
set -euo pipefail

# QA helper: monitors /run/alphaos/license-status and records transitions
# to validate zenity warnings + grace countdown behavior.

STATUS_FILE="/run/alphaos/license-status"
OUTPUT="${1:-/tmp/license-status-log.csv}"
INTERVAL="${INTERVAL:-60}"
HEADER="timestamp,status,message,failures"

log() {
  printf '%s\n' "$*" >&2
}

ensure_status() {
  local waited=0
  while [[ ! -s "$STATUS_FILE" ]]; do
    sleep 2
    waited=$((waited + 2))
    if (( waited >= 30 )); then
      log "Waiting for license status feed..."
      waited=0
    fi
  done
}

main() {
  ensure_status
  if [[ ! -f "$OUTPUT" ]]; then
    echo "$HEADER" >"$OUTPUT"
  fi
  log "Logging license status changes to $OUTPUT (poll every ${INTERVAL}s)"
  local last_line=""
  while true; do
    if [[ -s "$STATUS_FILE" ]]; then
      local current
      current="$(cat "$STATUS_FILE")"
      if [[ "$current" != "$last_line" ]]; then
        IFS='|' read -r status message timestamp failures <<<"$current"
        printf '%s,%s,"%s",%s\n' "$timestamp" "$status" "$message" "${failures:-0}" >>"$OUTPUT"
        last_line="$current"
        log "Captured status $status (failures=${failures:-0})"
      fi
    fi
    sleep "$INTERVAL"
  done
}

main "$@"
