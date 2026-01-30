#!/usr/bin/env bash
# Version 7.0: lean kiosk launcher supporting Chromium or Firefox.
set -euo pipefail

PRIMARY_URL="${PRIMARY_URL:-https://furnituredistributors.net}"
SECONDARY_URL="${SECONDARY_URL:-https://alphaonlines.org/pages/aj-test}"
TARGET_URL="${TARGET_URL:-$PRIMARY_URL}"
DEBUG_PORT="${DEBUG_PORT:-9222}"
BROWSER="${BROWSER:-chromium}"            # chromium|firefox
PROFILE_DIR="${PROFILE_DIR:-$HOME/.local/share/kiosk-${BROWSER}}"

export DISPLAY="${DISPLAY:-:0}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"

# Keep the screen awake and cursor hidden.
if command -v xset >/dev/null 2>&1; then
  xset s off -dpms || true
  xset s noblank || true
fi
command -v unclutter >/dev/null 2>&1 && unclutter --timeout 1 --start-hidden &

mkdir -p "$PROFILE_DIR"

detect_touch_device() {
  local ev=""
  if [ -r /proc/bus/input/devices ]; then
    ev="$(awk '
      /^N: Name=/ {
        name = $0
        lname = tolower($0)
        is_touch = (lname ~ /touch/ && lname !~ /touchpad/)
      }
      /^H: Handlers=/ && is_touch {
        if (match($0, /event[0-9]+/)) {
          print substr($0, RSTART, RLENGTH)
          exit
        }
        is_touch = 0
      }
    ' /proc/bus/input/devices)"
  fi
  if [ -n "$ev" ] && [ -e "/dev/input/$ev" ]; then
    printf "/dev/input/%s" "$ev"
  fi
}

launch_chromium() {
  local bin="chromium"
  command -v chromium-browser >/dev/null 2>&1 && bin="chromium-browser"
  command -v google-chrome >/dev/null 2>&1 && bin="google-chrome"
  local touch_device="${TOUCH_DEVICE:-}"
  if [ -z "$touch_device" ]; then
    touch_device="$(detect_touch_device || true)"
  fi
  local touch_flags=(--touch-events=enabled --force-touch-events)
  if [ -n "$touch_device" ]; then
    touch_flags+=(--touch-devices="$touch_device")
  fi

  exec "$bin" \
    --user-data-dir="$PROFILE_DIR" \
    --new-window \
    --kiosk \
    --noerrdialogs \
    --disable-translate \
    --disable-features=TranslateUI \
    --disable-infobars \
    --disable-pinch \
    --overscroll-history-navigation=0 \
    --password-store=basic \
    --enable-features=OverlayScrollbar,VirtualKeyboard,TouchVirtualKeyboard \
    --force-renderer-accessibility \
    "${touch_flags[@]}" \
    --test-type \
    --no-first-run \
    --no-default-browser-check \
    --remote-debugging-address=127.0.0.1 \
    --remote-debugging-port="$DEBUG_PORT" \
    "$TARGET_URL"
}

launch_firefox() {
  local bin="firefox-esr"
  command -v firefox >/dev/null 2>&1 && bin="firefox"

  exec "$bin" \
    --profile "$PROFILE_DIR" \
    --kiosk \
    --new-instance \
    --no-remote \
    --width=1920 \
    --height=1080 \
    --start-debugger-server "127.0.0.1:${DEBUG_PORT}" \
    "$TARGET_URL"
}

case "${BROWSER,,}" in
  firefox|firefox-esr) launch_firefox ;;
  *) launch_chromium ;;
esac
