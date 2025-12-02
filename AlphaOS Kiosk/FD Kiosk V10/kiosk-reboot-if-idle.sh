#!/usr/bin/env bash
# Version 7.0: nightly reboot prompt with skip option.
set -euo pipefail

export DISPLAY="${DISPLAY:-:0}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

MSG="${MSG:-Reboot is scheduled. Click 'Skip tonight' to cancel.}"
PROMPT_TIMEOUT="${PROMPT_TIMEOUT:-90}"

log() {
  command -v logger >/dev/null 2>&1 && logger -t kiosk-reboot "$*" || echo "$*" >&2
}

reboot_now() {
  for cmd in "loginctl reboot" "systemctl reboot" "shutdown -r now"; do
    if $cmd >/dev/null 2>&1; then
      return 0
    fi
  done
  log "Reboot command failed (loginctl/systemctl/shutdown not permitted)."
  return 1
}

if command -v zenity >/dev/null 2>&1; then
  zenity --question \
    --title="Maintenance reboot" \
    --text="$MSG" \
    --ok-label="Reboot now" \
    --cancel-label="Skip tonight" \
    --timeout="$PROMPT_TIMEOUT"
  case $? in
    0) reboot_now ;;
    *) exit 0 ;;
  esac
else
  log "zenity not installed; rebooting without prompt."
  reboot_now
fi
