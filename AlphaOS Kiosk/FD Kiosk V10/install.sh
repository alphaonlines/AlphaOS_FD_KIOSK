#!/usr/bin/env bash
# Version 10.0 installer: deploys kiosk scripts, systemd units, and autostart with xvkbd external keyboard support.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

KIOSK_USER="${KIOSK_USER:-fduser}"
PRIMARY_URL="${PRIMARY_URL:-https://furnituredistributors.net}"
SECONDARY_URL="${SECONDARY_URL:-https://AlphaonlineS.github.io/AlphaPulse}"
DEBUG_PORT="${DEBUG_PORT:-9222}"
REBOOT_TIME="${REBOOT_TIME:-03:30}"
BROWSER="${BROWSER:-chromium}" # chromium|firefox
PROFILE_DIR="${PROFILE_DIR:-${KIOSK_HOME:-$(eval echo "~${KIOSK_USER}")}/.local/share/kiosk-${BROWSER}}"
SKIP_APT="${SKIP_APT:-0}"

KIOSK_HOME="$(eval echo "~${KIOSK_USER}")"
BIN_DIR="${KIOSK_HOME}/bin"
AUTOSTART_DIR="${KIOSK_HOME}/.config/autostart"
SYSTEMD_DIR="${KIOSK_HOME}/.config/systemd/user"

log() { echo "[+] $*"; }
warn() { echo "[!] $*" >&2; }

ensure_user() {
  if id "$KIOSK_USER" >/dev/null 2>&1; then
    return
  fi
  warn "User $KIOSK_USER missing; creating."
  sudo useradd -m -s /bin/bash "$KIOSK_USER"
}

install_packages() {
  local pkgs=(
    chromium chromium-sandbox firefox-esr
    xdotool wmctrl unclutter zenity
    jq curl dbus-x11 x11-xserver-utils
    python3-tk python3-requests
    xvkbd xfonts-75dpi xfonts-100dpi
  )
  if [ "$SKIP_APT" != "0" ]; then
    warn "SKIP_APT=1 set; skipping package install. Ensure dependencies are present."
    return
  fi
  if command -v apt >/dev/null 2>&1; then
    log "Installing packages (requires sudo)..."
    sudo apt update
    sudo apt install -y "${pkgs[@]}" || warn "Package install had issues; continue to deploy configs."
  else
    warn "apt not available; install dependencies manually: ${pkgs[*]}"
  fi
}

configure_virtual_keyboard() {
  log "Configuring virtual keyboard support..."
  
  # Create chromium policies directory
  sudo mkdir -p /etc/chromium/policies/managed
  
  # Create virtual keyboard policy file
  sudo tee /etc/chromium/policies/managed/virtual_keyboard.json > /dev/null <<EOF
{
  "VirtualKeyboardEnabled": true,
  "TouchVirtualKeyboardEnabled": true,
  "URLBlacklist": ["chrome://*", "file://*"],
  "AllowFileSelectionDialogs": false
}
EOF
  
  # Add to /etc/chromium.d/default-flags for system-wide configuration
  if [ -f "/etc/chromium.d/default-flags" ]; then
    log "Adding virtual keyboard flags to /etc/chromium.d/default-flags"
    sudo tee -a /etc/chromium.d/default-flags > /dev/null <<EOF

# Virtual keyboard support for touch screens
export CHROMIUM_FLAGS="\$CHROMIUM_FLAGS --enable-features=OverlayScrollbar,VirtualKeyboard,TouchVirtualKeyboard"
export CHROMIUM_FLAGS="\$CHROMIUM_FLAGS --touch-events=enabled"
export CHROMIUM_FLAGS="\$CHROMIUM_FLAGS --force-touch-events"
EOF
  fi
  
  log "Virtual keyboard configuration completed"
}

configure_xvkbd_keyboard() {
  log "Configuring xvkbd external keyboard support..."
  
  # Create .Xresources file for optimal xvkbd display
  sudo -u "$KIOSK_USER" tee "$KIOSK_HOME/.Xresources" > /dev/null <<EOF
! Custom xvkbd resource file for large 3X keyboard (1200x600)
! Optimized for kiosk display with bold, visible fonts

! Main font configuration - bold bitmap for excellent visibility
xvkbd*Font: 9x15bold

! Enhanced font sizes for different keyboard elements
xvkbd*generalFont: 9x15bold
xvkbd*letterFont: 9x15bold
xvkbd*specialFont: 9x15bold
xvkbd*keypadFont: 9x15

! Larger key sizes for 3X scaling (default is 30x30)
xvkbd*Command.height: 90
xvkbd*Repeater.height: 90
xvkbd*Command.width: 90
xvkbd*Repeater.width: 90

! Larger space bar and special keys
xvkbd*space.width: 240
xvkbd*Tab.width: 135
xvkbd*Control_L.width: 180
xvkbd*Shift_L.width: 225
xvkbd*Shift_R.width: 120
xvkbd*BackSpace.width: 225
xvkbd*Delete.width: 135
xvkbd*Return.width: 180

! Enhanced spacing for large keyboard
xvkbd*row1.vertDistance: 15
xvkbd*F5.horizDistance: 15
xvkbd*F9.horizDistance: 15
xvkbd*BackSpace.horizDistance: 15

! Better contrast and visibility
xvkbd*Background: gray90
xvkbd*Foreground: black
xvkbd*highlightBackground: lightblue
xvkbd*highlightForeground: darkblue

! Enhanced shadow for better key definition
xvkbd*shadowWidth: 3
xvkbd*topShadowContrast: 50
xvkbd*bottomShadowContrast: 90

! Center alignment for better appearance
xvkbd*Command.justify: center
xvkbd*Repeater.justify: center
xvkbd*Command.internalWidth: 4
xvkbd*Repeater.internalWidth: 4

! Window geometry for 3X size keyboard
xvkbd.windowGeometry: 1200x600+360+460
EOF
  
  # Load the X resources for the user
  sudo -u "$KIOSK_USER" xrdb -merge "$KIOSK_HOME/.Xresources" || warn "Failed to load X resources"
  
  log "xvkbd keyboard configuration completed"
}

deploy_scripts() {
  log "Copying scripts to ${BIN_DIR}"
  mkdir -p "$BIN_DIR"
  install -m 755 "$ROOT_DIR/kiosk-session.sh" "$BIN_DIR/kiosk-session.sh"
  install -m 755 "$ROOT_DIR/kiosk-ui.py" "$BIN_DIR/kiosk-ui.py"
  install -m 755 "$ROOT_DIR/kioskctl" "$BIN_DIR/kioskctl"
  install -m 755 "$ROOT_DIR/kiosk-reboot-if-idle.sh" "$BIN_DIR/kiosk-reboot-if-idle.sh"
  chown -R "$KIOSK_USER":"$KIOSK_USER" "$BIN_DIR"
}

write_unit() {
  local path="$1"; shift
  cat > "$path" <<EOF
$*
EOF
}

deploy_units() {
  log "Rendering systemd user units"
  mkdir -p "$SYSTEMD_DIR"

  write_unit "$SYSTEMD_DIR/kiosk-session.service" "[Unit]
Description=Kiosk browser session
After=graphical-session.target network-online.target

[Service]
Type=simple
Environment=PRIMARY_URL=${PRIMARY_URL}
Environment=SECONDARY_URL=${SECONDARY_URL}
Environment=DEBUG_PORT=${DEBUG_PORT}
Environment=BROWSER=${BROWSER}
Environment=PROFILE_DIR=${PROFILE_DIR}
ExecStart=${BIN_DIR}/kiosk-session.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target"

  write_unit "$SYSTEMD_DIR/kiosk-ui.service" "[Unit]
Description=Kiosk floating UI (toggle/back/scroll)
After=graphical-session.target

[Service]
Type=simple
Environment=PRIMARY_URL=${PRIMARY_URL}
Environment=SECONDARY_URL=${SECONDARY_URL}
Environment=DEBUG_PORT=${DEBUG_PORT}
Environment=BROWSER=${BROWSER}
ExecStart=${BIN_DIR}/kiosk-ui.py
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target"

  write_unit "$SYSTEMD_DIR/kiosk-reboot.service" "[Unit]
Description=Nightly kiosk reboot prompt

[Service]
Type=oneshot
ExecStart=${BIN_DIR}/kiosk-reboot-if-idle.sh"

  write_unit "$SYSTEMD_DIR/kiosk-reboot.timer" "[Unit]
Description=Run nightly reboot prompt

[Timer]
OnCalendar=*-*-* ${REBOOT_TIME}
Persistent=true

[Install]
WantedBy=timers.target"

  write_unit "$SYSTEMD_DIR/kiosk.target" "[Unit]
Description=Kiosk suite (browser + overlays)
Wants=kiosk-session.service kiosk-ui.service kiosk-reboot.timer
After=graphical-session.target network-online.target
AllowIsolate=yes"

  chmod 644 "$SYSTEMD_DIR"/kiosk-*.service "$SYSTEMD_DIR"/kiosk-*.timer "$SYSTEMD_DIR/kiosk.target"
  chown -R "$KIOSK_USER":"$KIOSK_USER" "$SYSTEMD_DIR"
}

deploy_autostart() {
  log "Adding autostart entry"
  mkdir -p "$AUTOSTART_DIR"
  cat > "$AUTOSTART_DIR/kiosk.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Kiosk Suite
Exec=${BIN_DIR}/kioskctl start
X-GNOME-Autostart-enabled=true
EOF
  chmod 644 "$AUTOSTART_DIR/kiosk.desktop"
  chown -R "$KIOSK_USER":"$KIOSK_USER" "$AUTOSTART_DIR"
}

enable_units() {
  log "Enabling kiosk units for ${KIOSK_USER}"
  sudo -u "$KIOSK_USER" systemctl --user daemon-reload || true
  sudo -u "$KIOSK_USER" systemctl --user enable kiosk.target kiosk-reboot.timer || true
}

detect_desktop_env() {
  local desktop="${XDG_CURRENT_DESKTOP:-}"
  if [[ "$desktop" == *"GNOME"* ]] || [[ "$desktop" == *"ubuntu"* ]]; then
    echo "gnome"
  elif [[ "$desktop" == *"XFCE"* ]]; then
    echo "xfce"
  else
    echo "unknown"
  fi
}

install_branding() {
  local src="$ROOT_DIR/alphaos-kiosk.png"
  if [ -f "$src" ]; then
    log "Copying branding image to /usr/share/backgrounds/ (requires sudo)"
    sudo mkdir -p /usr/share/backgrounds
    sudo cp "$src" /usr/share/backgrounds/alphaos-kiosk.png
    
    local desktop_env
    desktop_env=$(detect_desktop_env)
    log "Detected desktop environment: ${desktop_env}"
    
    case "$desktop_env" in
      "gnome")
        log "Setting GNOME desktop background for ${KIOSK_USER}"
        sudo -u "$KIOSK_USER" gsettings set org.gnome.desktop.background picture-uri "file:///usr/share/backgrounds/alphaos-kiosk.png" || warn "Failed to set GNOME background"
        sudo -u "$KIOSK_USER" gsettings set org.gnome.desktop.background picture-uri-dark "file:///usr/share/backgrounds/alphaos-kiosk.png" || warn "Failed to set GNOME dark background"
        ;;
      "xfce")
        log "Setting XFCE desktop background"
        # Set for monitor 0, workspace 0
        sudo -u "$KIOSK_USER" xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s "/usr/share/backgrounds/alphaos-kiosk.png" || warn "Failed to set XFCE background path"
        sudo -u "$KIOSK_USER" xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "/usr/share/backgrounds/alphaos-kiosk.png" || warn "Failed to set XFCE workspace background"
        sudo -u "$KIOSK_USER" xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-show -s true || warn "Failed to enable XFCE background image"
        # Try to set for monitor 1 if it exists
        sudo -u "$KIOSK_USER" xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor1/workspace0/last-image -s "/usr/share/backgrounds/alphaos-kiosk.png" 2>/dev/null || true
        ;;
      *)
        warn "Unknown desktop environment. Background may need to be set manually."
        warn "For GNOME: gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/alphaos-kiosk.png'"
        warn "For XFCE: xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -s '/usr/share/backgrounds/alphaos-kiosk.png'"
        ;;
    esac
  fi
}

configure_autologin() {
  log "Configuring LightDM autologin..."
  
  local lightdm_conf="/etc/lightdm/lightdm.conf"
  if [ -f "$lightdm_conf" ]; then
    # Backup original
    sudo cp "$lightdm_conf" "$lightdm_conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Configure autologin
    sudo sed -i "s/^#autologin-user=.*/autologin-user=$KIOSK_USER/" "$lightdm_conf"
    sudo sed -i "s/^#autologin-user-timeout=.*/autologin-user-timeout=0/" "$lightdm_conf"
    sudo sed -i "s/^autologin-user=.*/autologin-user=$KIOSK_USER/" "$lightdm_conf"
    sudo sed -i "s/^autologin-user-timeout=.*/autologin-user-timeout=0/" "$lightdm_conf"
    
    log "LightDM autologin configured for user $KIOSK_USER"
  else
    warn "LightDM config not found at $lightdm_conf"
  fi
}

main() {
  ensure_user
  install_packages
  configure_virtual_keyboard
  configure_xvkbd_keyboard
  deploy_scripts
  deploy_units
  deploy_autostart
  install_branding
  configure_autologin
  enable_units

  log "Done. Reboot or log out/in to start kiosk."
  echo "Manage with: kioskctl start|stop|restart|status|logs|doctor"
  echo "Change URLs/env: set PRIMARY_URL/SECONDARY_URL/BROWSER/REBOOT_TIME then re-run install.sh"
  echo "Virtual keyboard support enabled for touch screens"
  echo "xvkbd external keyboard with 9x15bold font integrated"
}

main "$@"
