# FD Kiosk V11 Runbook

This is the single starting point for setup, smoke testing, and production prep.

## 1) Kiosk App (V11) Install
```bash
cd "/home/fduser/Desktop/FD Kiosk V11"
chmod +x *.sh kioskctl
./install.sh
```

## 2) Kiosk Shell (Local Smoke Test)
See:
- `kiosk shell/INTEGRATION.md`
- `kiosk shell/SMOKE_TEST.md`

If you need a quick local stack start/stop:
```bash
./kiosk\ shell/start_local_stack.sh
./kiosk\ shell/stop_local_stack.sh
```

## 3) Production Prep
See:
- `kiosk shell/PRODUCTION_CHECKLIST.md`
- `kiosk shell/server/controller/config.prod.sample.json`
- `kiosk shell/server/dashboard/config.prod.sample.json`
- `kiosk shell/agent/config/config.prod.sample.json`

Server install helper:
```bash
cd "/home/fduser/Desktop/FD Kiosk V11/kiosk shell"
sudo ./install_server.sh
```

## 4) Architecture + Scope
See:
- `kiosk shell/SCHEMA.md`
- `kiosk shell/agents/AGENTS_ALL.md`

## TODO (Parking Lot)
- Add Dockerfiles for broker + agent.
- Create `docker-compose.prod.yml` with production volumes and cert mounts.
- Expand `install_server.sh` to create `/etc/kiosk-*` directories and log rotation.
- Add minimal auth to dashboard (token or IP allowlist).
- Document certificate rotation and revocation.
