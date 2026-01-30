# Integration Runbook (MVP)

## Prereqs
- Python 3.13 on kiosks (Debian 13)
- Python 3.10+ on server
- Mosquitto on server
- A shared internal CA

## 1) Broker + mTLS
- Create CA and server certs (see `server/broker/certs/README.md`).
- Configure Mosquitto with mTLS and ACLs.
- Start Mosquitto on the VPS.

## 2) Controller API
- Configure `server/controller/config.sample.json` -> `config.json`.
- Install deps: `pip install -r requirements.txt`.
- Run: `python app.py`.

## 3) Kiosk Agent
- Install agent dependencies.
- Copy `agent/config/config.sample.json` to `/etc/kiosk-agent/config.json`.
- Install client certs to `/etc/kiosk-agent/certs/`.
- Install systemd service and timer from `agent/systemd/`.
- Start service and verify heartbeats.

## 4) Dashboard
- Configure the dashboard to point to controller API.
- Start dashboard locally (see `server/dashboard/`).

## Smoke Tests
- Publish a command from dashboard -> kiosk receives.
- Kiosk posts reply -> controller stores and dashboard shows history.
- Heartbeat updates last_seen.

## Acceptance Criteria
- mTLS enforced; no anonymous clients.
- Heartbeats appear in dashboard within 60s.
- Commands round-trip in under 2 minutes (immediate mode).
