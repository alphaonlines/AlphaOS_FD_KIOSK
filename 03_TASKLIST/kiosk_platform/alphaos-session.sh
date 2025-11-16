#!/usr/bin/env bash
set -euo pipefail

export MOZ_ENABLE_WAYLAND=0
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export PORTAL_URL_FILE="/etc/alphaos/license-url"
export PORTAL_URL=${PORTAL_URL:-"https://alphaos.example/kiosk"}

# Allow override via /etc/alphaos/portal-url
if [[ -f /etc/alphaos/portal-url ]]; then
  PORTAL_URL=$(tr -d '\r' < /etc/alphaos/portal-url | sed -n '1p')
fi

# Xorg only
xset -dpms
xset s off
unclutter -idle 0.5 &

matchbox-window-manager -use_titlebar no -use_cursor no &
matchbox_pid=$!

if [[ -x /usr/local/bin/alphaos-touch-config.sh ]]; then
  /usr/local/bin/alphaos-touch-config.sh &
fi

onboard --xid --not-show-in-indicator --theme HighContrast --size 1200x360 &
onboard_pid=$!

LICENSE_STATUS_SOCKET="/run/alphaos/license-status"
LICENSE_WATCH_BIN="/usr/local/bin/alphaos-license-watch.sh"
mkdir -p "$(dirname "$LICENSE_STATUS_SOCKET")"
chmod 770 "$(dirname "$LICENSE_STATUS_SOCKET")"

PORTAL_URL_CONTENT=$(tr -d '\r' < "$PORTAL_URL_FILE" | sed -n '1p')
if [[ -n "$PORTAL_URL_CONTENT" ]]; then
  PORTAL_URL="$PORTAL_URL_CONTENT"
fi

firefox --kiosk --private-window "$PORTAL_URL" &
firefox_pid=$!
license_watch_pid=0
if [[ -x "$LICENSE_WATCH_BIN" ]]; then
  "$LICENSE_WATCH_BIN" &
  license_watch_pid=$!
fi

cleanup() {
  kill "$firefox_pid" "$matchbox_pid" "$onboard_pid" "$license_watch_pid" 2>/dev/null || true
}
trap cleanup EXIT

wait "$firefox_pid"
