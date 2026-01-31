# Production Readiness Checklist (Kiosk Shell)

This checklist is for moving the kiosk shell MVP from local testing to production.

## 1) Certificates + Identity
- [ ] Create internal CA (offline storage + backup).
- [ ] Issue server cert for broker (SAN includes broker host/IP).
- [ ] Issue one client cert per kiosk (CN == kiosk_id).
- [ ] Issue controller client cert (CN == controller).
- [ ] Define cert rotation and revocation process.

## 2) Broker (Mosquitto)
- [ ] Install mosquitto on server (system package).
- [ ] Configure mTLS + ACLs.
- [ ] Bind to production interface/port and lock down firewall.
- [ ] Enable service + auto-restart.
- [ ] Verify anonymous clients are rejected.

## 3) Controller API
- [ ] Configure `server/controller/config.json` for production broker + DB path.
- [ ] Install deps in a venv or system package.
- [ ] Run behind a production WSGI server (gunicorn/uwsgi).
- [ ] Configure systemd service + logs.
- [ ] Confirm publish failures are recorded.

## 4) Dashboard
- [ ] Configure `server/dashboard/config.json` to point at controller.
- [ ] Install deps and run behind a production server.
- [ ] Add auth (even a shared token) or restrict network access.
- [ ] Confirm history output truncates gracefully.

## 5) Kiosk Agent
- [ ] Install agent to `/opt/kiosk-agent` (or final chosen path).
- [ ] Install update runner to `/usr/local/lib/kiosk-agent/update_runner.sh`.
- [ ] Copy config to `/etc/kiosk-agent/config.json`.
- [ ] Install certs to `/etc/kiosk-agent/certs/`.
- [ ] Enable `kiosk-agent.service` + `kiosk-agent.timer`.
- [ ] Confirm `KIOSK_REPO_PATH` and service names are correct.

## 6) Kiosk App (V11)
- [ ] Run `/home/fduser/Desktop/FD Kiosk V11/install.sh`.
- [ ] Verify `kiosk-session.service` and `kiosk-ui.service` exist.
- [ ] Confirm touch keyboard and toggle behavior.

## 7) Security + Ops
- [ ] Firewall broker + controller ports.
- [ ] Log rotation for broker/controller/agent.
- [ ] Backup controller DB (`server/data/`).
- [ ] Monitor disk usage and uptime.

## 8) Smoke Test (Production)
- [ ] Heartbeat appears within 60s in dashboard.
- [ ] Command round-trip completes in <2 minutes.
- [ ] Nightly queue executes at scheduled window.
