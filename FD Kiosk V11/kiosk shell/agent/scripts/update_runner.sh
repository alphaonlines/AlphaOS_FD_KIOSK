#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
if [[ -z "${action}" ]]; then
  echo "usage: update_runner.sh <action>" >&2
  exit 2
fi

log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"
}

run_update_os() {
  log "Running apt update/upgrade"
  apt update
  DEBIAN_FRONTEND=noninteractive apt upgrade -y
}

run_update_repo() {
  if [[ -z "${KIOSK_REPO_PATH:-}" ]]; then
    echo "KIOSK_REPO_PATH not set" >&2
    exit 3
  fi
  log "Updating repo at ${KIOSK_REPO_PATH}"
  git -C "${KIOSK_REPO_PATH}" pull --ff-only
}

run_install() {
  if [[ -z "${KIOSK_REPO_PATH:-}" ]]; then
    echo "KIOSK_REPO_PATH not set" >&2
    exit 3
  fi
  log "Running install script"
  (cd "${KIOSK_REPO_PATH}" && SKIP_APT=1 ./install.sh)
}

run_restart_services() {
  log "Restarting kiosk services"
  systemctl --user restart kiosk-session.service kiosk-ui.service || true
  systemctl restart kiosk-session.service kiosk-ui.service || true
}

run_reboot() {
  log "Rebooting system"
  systemctl reboot
}

run_update_full() {
  run_update_os
  run_update_repo
  run_install
  run_restart_services
}

case "${action}" in
  update_full) run_update_full ;;
  update_os) run_update_os ;;
  update_repo) run_update_repo ;;
  run_install) run_install ;;
  restart_services) run_restart_services ;;
  reboot) run_reboot ;;
  *)
    echo "Unknown action: ${action}" >&2
    exit 4
    ;;
esac
