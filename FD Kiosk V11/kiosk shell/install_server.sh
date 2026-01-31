#!/usr/bin/env bash
set -euo pipefail

# Server-side install helper for controller + dashboard + systemd units.
# Requires root privileges.

KIOSK_USER="${KIOSK_USER:-kiosk}"
INSTALL_DIR="${INSTALL_DIR:-/opt/kiosk-shell}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run as root (sudo)." >&2
  exit 1
fi

if ! id -u "${KIOSK_USER}" >/dev/null 2>&1; then
  useradd --system --create-home --shell /usr/sbin/nologin "${KIOSK_USER}"
fi

mkdir -p "${INSTALL_DIR}"
rsync -a --delete --exclude '__pycache__' "./server/" "${INSTALL_DIR}/server/"

install -m 0644 "./server/systemd/kiosk-controller.service" /etc/systemd/system/kiosk-controller.service
install -m 0644 "./server/systemd/kiosk-dashboard.service" /etc/systemd/system/kiosk-dashboard.service

systemctl daemon-reload
systemctl enable kiosk-controller.service
systemctl enable kiosk-dashboard.service

echo "Installed to ${INSTALL_DIR}. Update configs in ${INSTALL_DIR}/server/* and start services when ready."
