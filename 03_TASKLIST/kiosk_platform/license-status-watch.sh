#!/usr/bin/env bash
set -euo pipefail

# Monitors /run/alphaos/license-status for failure events and surfaces them to the kiosk user.

STATUS_FILE="/run/alphaos/license-status"
GRACE_LIMIT="${GRACE_LIMIT:-16}"
WARN_CMD="${WARN_CMD:-zenity}"
WARN_TITLE="AlphaOS License Notice"
WARN_WIDTH="${WARN_WIDTH:-640}"
WARN_HEIGHT="${WARN_HEIGHT:-200}"

log() {
  printf '%s\n' "$*" >&2
}

wait_for_status_file() {
  local waited=0
  while [[ ! -s "$STATUS_FILE" ]]; do
    sleep 2
    waited=$((waited + 2))
    if (( waited > 60 )); then
      log "Still waiting for $STATUS_FILE..."
      waited=0
    fi
  done
}

show_warning() {
  local message="$1"
  if [[ "$WARN_CMD" == "zenity" ]] && command -v zenity >/dev/null 2>&1; then
    zenity --warning --no-wrap --title "$WARN_TITLE" \
      --width "$WARN_WIDTH" --height "$WARN_HEIGHT" \
      --text "$message" &
    echo $!
  else
    log "WARNING: $message"
    echo 0
  fi
}

dismiss_warning() {
  local pid="$1"
  if (( pid > 0 )) && kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
  fi
}

main() {
  wait_for_status_file
  local current_pid=0
  tail -Fn0 "$STATUS_FILE" | while read -r line; do
    [[ -z "$line" ]] && continue
    IFS='|' read -r status reason timestamp failures <<<"$line"
    failures=${failures:-0}
    if [[ "$status" == "FAIL" ]]; then
      local remaining=$(( GRACE_LIMIT - failures ))
      (( remaining < 0 )) && remaining=0
      local msg="License validation failed ($reason). Kiosk will lock after $remaining more attempts."
      dismiss_warning "$current_pid"
      current_pid=$(show_warning "$msg")
    else
      dismiss_warning "$current_pid"
      current_pid=0
    fi
  done
}

main "$@"
