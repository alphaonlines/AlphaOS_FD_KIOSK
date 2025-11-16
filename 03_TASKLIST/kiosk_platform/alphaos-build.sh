#!/usr/bin/env bash
set -euo pipefail

# AlphaOS kiosk build helper
# Creates a jammy-based rootfs, installs kiosk packages, and stages configs.

if [[ ${EUID} -ne 0 ]]; then
  echo "This script must run as root (use sudo)." >&2
  exit 1
fi

if [[ $# -lt 1 ]]; then
  cat >&2 <<'USAGE'
Usage: sudo ./alphaos-build.sh <output-dir> [mirror]
  <output-dir>   Directory that will contain the AlphaOS rootfs (created if missing).
  [mirror]       Optional Ubuntu mirror (default: http://archive.ubuntu.com/ubuntu).

This script expects to be executed from the repo root so it can read:
  - 00_PLACE START FILE HERE/New Text Document.txt  (license URL source)
  - 03_TASKLIST/kiosk_platform/alphaos-session.sh   (session launcher)
  - 03_TASKLIST/kiosk_platform/systemd/...          (systemd overrides)
USAGE
  exit 1
fi

BUILD_DIR="$(readlink -f "$1")"
MIRROR="${2:-http://archive.ubuntu.com/ubuntu}"
RELEASE="jammy"
ROOTFS="$BUILD_DIR/rootfs"
CHROOT_SCRIPT="$BUILD_DIR/alphaos-chroot.sh"
LICENSE_URL_FILE="00_PLACE START FILE HERE/New Text Document.txt"
SESSION_SCRIPT="03_TASKLIST/kiosk_platform/alphaos-session.sh"
SYSTEMD_DIR_SRC="03_TASKLIST/kiosk_platform/systemd"
LICENSE_SCRIPT_SRC="03_TASKLIST/security_licensing/license-check.sh"
LICENSE_IMAGE_SCRIPT_SRC="03_TASKLIST/security_licensing/license-image-check.sh"
LICENSE_SYSTEMD_SRC="03_TASKLIST/security_licensing/systemd"
PLYMOUTH_SRC_DIR="03_TASKLIST/brand_ux/plymouth"
FIREFOX_POLICY_SRC="03_TASKLIST/brand_ux/firefox/policies.json"
LICENSE_WATCHER_SRC="03_TASKLIST/kiosk_platform/license-status-watch.sh"
TOUCH_CONFIG_SRC="03_TASKLIST/firmware_hardware/touch-config.sh"
TOUCH_QUIRKS_SRC="03_TASKLIST/firmware_hardware/libinput-local-overrides.quirks"
TOUCH_XORG_SRC="03_TASKLIST/firmware_hardware/99-alphaos-touch.conf"

mkdir -p "$BUILD_DIR"

if [[ ! -f "$LICENSE_URL_FILE" ]]; then
  echo "Missing license URL file at $LICENSE_URL_FILE" >&2
  exit 1
fi
if [[ ! -f "$SESSION_SCRIPT" ]]; then
  echo "Missing session script at $SESSION_SCRIPT" >&2
  exit 1
fi
if [[ ! -f "$LICENSE_SCRIPT_SRC" ]]; then
  echo "Missing license script at $LICENSE_SCRIPT_SRC" >&2
  exit 1
fi
if [[ ! -f "$LICENSE_IMAGE_SCRIPT_SRC" ]]; then
  echo "Missing license image script at $LICENSE_IMAGE_SCRIPT_SRC" >&2
  exit 1
fi
if [[ ! -d "$PLYMOUTH_SRC_DIR" ]]; then
  echo "Missing Plymouth theme directory at $PLYMOUTH_SRC_DIR" >&2
  exit 1
fi
if [[ ! -f "$FIREFOX_POLICY_SRC" ]]; then
  echo "Missing Firefox policy file at $FIREFOX_POLICY_SRC" >&2
  exit 1
fi
if [[ ! -f "$LICENSE_WATCHER_SRC" ]]; then
  echo "Missing license watcher script at $LICENSE_WATCHER_SRC" >&2
  exit 1
fi
if [[ ! -f "$TOUCH_CONFIG_SRC" ]]; then
  echo "Missing touch config script at $TOUCH_CONFIG_SRC" >&2
  exit 1
fi
if [[ ! -f "$TOUCH_QUIRKS_SRC" ]]; then
  echo "Missing libinput quirks file at $TOUCH_QUIRKS_SRC" >&2
  exit 1
fi
if [[ ! -f "$TOUCH_XORG_SRC" ]]; then
  echo "Missing Xorg calibration file at $TOUCH_XORG_SRC" >&2
  exit 1
fi

LICENSE_URL=$(tr -d '\r' < "$LICENSE_URL_FILE" | sed -n '1p')

if [[ -z "$LICENSE_URL" ]]; then
  echo "License URL file is empty" >&2
  exit 1
fi

echo "[*] Creating rootfs under $ROOTFS"
rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"

debootstrap --variant=minbase "$RELEASE" "$ROOTFS" "$MIRROR"

cat > "$CHROOT_SCRIPT" <<CHROOT
#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \\
    systemd-sysv sudo dbus dbus-x11 ca-certificates locales tzdata \\
    linux-generic xorg xserver-xorg-input-libinput xserver-xorg-video-intel xserver-xorg-video-vesa \\
    matchbox-window-manager onboard unclutter firefox-esr network-manager openssh-server policykit-1 \\
    ufw curl jq fonts-noto gsettings-desktop-schemas x11-xserver-utils rsyslog mesa-utils \\
    plymouth plymouth-themes plymouth-x11 zenity

# Create kiosk user
id -u kiosk &>/dev/null || useradd -m -s /bin/bash kiosk
usermod -aG sudo kiosk
passwd -d kiosk
mkdir -p /etc/alphaos
cat <<'EOF_LIC' > /etc/alphaos/license-url
$LICENSE_URL
EOF_LIC
chown root:root /etc/alphaos/license-url
chmod 644 /etc/alphaos/license-url

# Locale + timezone defaults
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
ln -fs /usr/share/zoneinfo/UTC /etc/localtime

touch /etc/systemd/system/getty@tty1.service.d/.keep

echo 'kiosk ALL=(ALL) NOPASSWD: /sbin/reboot, /sbin/poweroff' >/etc/sudoers.d/90-kiosk-power
chmod 440 /etc/sudoers.d/90-kiosk-power

systemctl enable NetworkManager systemd-timesyncd
systemctl enable ssh
systemctl enable ufw
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH

# Mask controls that allow kiosk escape paths
systemctl mask ctrl-alt-del.target
systemctl mask getty@tty2.service getty@tty3.service getty@tty4.service getty@tty5.service getty@tty6.service

# Dedicated service account for license validation
if ! id -u alphaos-licd &>/dev/null; then
  useradd --system --home /var/lib/alphaos --shell /usr/sbin/nologin alphaos-licd
fi
install -d -m 0750 -o alphaos-licd -g alphaos-licd /var/lib/alphaos
install -d -m 0770 -o alphaos-licd -g alphaos-licd /run/alphaos

# Firefox ESR pinning placeholder (actual pin handled via apt-mark hold at runtime)
CHROOT
chmod +x "$CHROOT_SCRIPT"

cp "$SESSION_SCRIPT" "$BUILD_DIR/alphaos-session.sh"
chmod +x "$BUILD_DIR/alphaos-session.sh"

cp -r "$SYSTEMD_DIR_SRC" "$BUILD_DIR/systemd"
cp "$LICENSE_SCRIPT_SRC" "$BUILD_DIR/license-check.sh"
cp "$LICENSE_IMAGE_SCRIPT_SRC" "$BUILD_DIR/license-image-check.sh"
chmod 0750 "$BUILD_DIR/license-check.sh" "$BUILD_DIR/license-image-check.sh"
cp -r "$LICENSE_SYSTEMD_SRC" "$BUILD_DIR/security-systemd"
cp -r "$PLYMOUTH_SRC_DIR" "$BUILD_DIR/plymouth-theme"
cp "$FIREFOX_POLICY_SRC" "$BUILD_DIR/firefox-policies.json"
cp "$LICENSE_WATCHER_SRC" "$BUILD_DIR/license-status-watch.sh"
chmod 0750 "$BUILD_DIR/license-status-watch.sh"
cp "$TOUCH_CONFIG_SRC" "$BUILD_DIR/alphaos-touch-config.sh"
chmod 0750 "$BUILD_DIR/alphaos-touch-config.sh"
cp "$TOUCH_QUIRKS_SRC" "$BUILD_DIR/libinput-local-overrides.quirks"
cp "$TOUCH_XORG_SRC" "$BUILD_DIR/99-alphaos-touch.conf"

cat <<'NEXT'
[*] Base rootfs created. To continue:
  sudo chroot "$ROOTFS" /bin/bash /alphaos-chroot.sh
  cp alphaos-session.sh "$ROOTFS/usr/local/bin/alphaos-session.sh"
  cp -r systemd/* "$ROOTFS/etc/systemd/system/"
  install -d "$ROOTFS/opt/alphaos"
  install -m 0750 license-check.sh "$ROOTFS/opt/alphaos/license-check.sh"
  install -m 0750 license-image-check.sh "$ROOTFS/opt/alphaos/license-image-check.sh"
  install -m 0750 license-status-watch.sh "$ROOTFS/usr/local/bin/alphaos-license-watch.sh"
  install -m 0750 alphaos-touch-config.sh "$ROOTFS/usr/local/bin/alphaos-touch-config.sh"
  mkdir -p "$ROOTFS/etc/libinput"
  install -m 0644 libinput-local-overrides.quirks "$ROOTFS/etc/libinput/local-overrides.quirks"
  mkdir -p "$ROOTFS/usr/share/X11/xorg.conf.d"
  install -m 0644 99-alphaos-touch.conf "$ROOTFS/usr/share/X11/xorg.conf.d/99-alphaos-touch.conf"
  cp security-systemd/alphaos-license-check.* "$ROOTFS/etc/systemd/system/"
  cp security-systemd/alphaos-license-image-check.* "$ROOTFS/etc/systemd/system/"
  mkdir -p "$ROOTFS/usr/share/plymouth/themes/alpha-kiosk"
  cp -r plymouth-theme/* "$ROOTFS/usr/share/plymouth/themes/alpha-kiosk/"
  mkdir -p "$ROOTFS/usr/lib/firefox/distribution" "$ROOTFS/usr/lib/firefox-esr/distribution"
  install -m 0644 firefox-policies.json "$ROOTFS/usr/lib/firefox/distribution/policies.json"
  install -m 0644 firefox-policies.json "$ROOTFS/usr/lib/firefox-esr/distribution/policies.json"
  chroot "$ROOTFS" systemctl enable alphaos-session.service
  chroot "$ROOTFS" systemctl enable alphaos-license-check.timer
  chroot "$ROOTFS" systemctl enable alphaos-license-image-check.timer
  chroot "$ROOTFS" plymouth-set-default-theme alpha-kiosk
  chroot "$ROOTFS" update-initramfs -u
  chroot "$ROOTFS" systemctl daemon-reload
  # Configure initramfs, grub, Plymouth, etc. afterwards.

Remember to package the rootfs into disk image (e.g., using systemd-nspawn or image builder).
NEXT
