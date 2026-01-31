# Kiosk Agent (MVP)

## What it does
- Connects to MQTT over mTLS and publishes heartbeats.
- Receives commands and runs them immediately or queues for nightly run.
- Reports command results back over MQTT.

## Install (example layout)
1. Copy `agent/` to `/opt/kiosk-agent/`.
2. Copy `agent/scripts/update_runner.sh` to `/usr/local/lib/kiosk-agent/update_runner.sh`.
3. Copy `agent/config/config.sample.json` to `/etc/kiosk-agent/config.json` and edit values.
   - For production, start from `agent/config/config.prod.sample.json`.
4. Install certs to `/etc/kiosk-agent/certs/`.
5. Install deps: `pip install paho-mqtt`.
6. Make scripts executable:
   - `chmod +x /opt/kiosk-agent/agent/agent.py /usr/local/lib/kiosk-agent/update_runner.sh`
7. Install systemd units from `agent/systemd/`:
   - `kiosk-agent.service`
   - `kiosk-agent-queue.service`
   - `kiosk-agent.timer`
8. Enable and start:
   - `systemctl enable --now kiosk-agent.service`
   - `systemctl enable --now kiosk-agent.timer`

## Notes
- `kiosk-agent.timer` runs queued commands nightly (edit `OnCalendar` to change time).
- `update_runner.sh` expects `KIOSK_REPO_PATH` to be set (service file includes it).
- Logs are written to `/var/lib/kiosk-agent/agent.log` and to the journal.
 - Production checklist: `../PRODUCTION_CHECKLIST.md`
