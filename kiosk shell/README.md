# Kiosk Shell Project Gameplan

This folder contains the long-term plan and checklist for building a centralized kiosk management system (updates, health dashboard, remote shell) for ~10 kiosks across different locations.

## Goals
- Central dashboard showing online/offline status per kiosk and location.
- Push updates to kiosks (OS + kiosk repo), executed on nightly window.
- Remote shell/terminal for troubleshooting.
- Secure communications (mutual TLS).
- Minimal downtime and safe rollbacks.

## Non-Goals (for now)
- Full MDM suite.
- Real-time UI streaming.
- Per-app sandboxing beyond the kiosk app.

## System Overview (Target Architecture)
- **Server**: VPS running MQTT broker (mTLS), controller API, and dashboard.
- **Kiosk Agent**: Lightweight daemon on each kiosk.
- **Transport**: MQTT over TLS + mTLS.
- **Remote Shell**: Reverse SSH tunnel to VPS (preferred), optional command execution over MQTT.

## Key Decisions (Locked or Pending)
- **mTLS**: ✅ approved
- **Nightly update window**: ✅ approved (fixed per kiosk)
- **Remote shell**: ✅ approved (reverse SSH preferred)
- **Server OS**: TODO
- **Agent language**: TODO (Python vs Go)
- **Dashboard stack**: TODO (Node/React vs Python/Flask)

## Gameplan (Phased)

### Phase 1 — Secure Comms + Heartbeats
- [ ] Choose server OS and provision VPS
- [ ] Create internal CA
- [ ] Generate client certs (1 per kiosk)
- [ ] Configure MQTT broker (Mosquitto) with mTLS
- [ ] Build kiosk agent (heartbeat + status payload)
- [ ] Register kiosks in dashboard DB
- [ ] Dashboard shows online/offline + last_seen

### Phase 2 — Updates + Nightly Scheduling
- [ ] Implement update runner script on kiosk
- [ ] Add job queue (JSON file or sqlite)
- [ ] Support commands: update_os, update_repo, run_install, restart_services, reboot
- [ ] Dashboard triggers commands per kiosk
- [ ] Nightly scheduler runs queued jobs
- [ ] Report job success/failure back to dashboard

### Phase 3 — Remote Shell
- [ ] Configure reverse SSH (autossh)
- [ ] Map kiosk IDs to SSH ports
- [ ] Dashboard shows "Connect" info
- [ ] Optional: command execution over MQTT (restricted)

### Phase 4 — Hardening & Rollback
- [ ] Signed update bundles or git commit pinning
- [ ] Health checks after update (service status + kiosk UI)
- [ ] Rollback plan (last known good git commit)
- [ ] Audit logs (who triggered what and when)

## Checklist (Per Kiosk)
- [ ] Kiosk ID assigned
- [ ] Location assigned
- [ ] Client cert installed
- [ ] Agent installed and enabled
- [ ] Reverse SSH configured
- [ ] Nightly schedule set
- [ ] First heartbeat received in dashboard
- [ ] Update test completed

## Dashboard Requirements
- [ ] List kiosks with status, location, last_seen, version
- [ ] Issue update commands (OS, repo, full)
- [ ] View job history + results
- [ ] Show remote shell connection details

## Security Checklist
- [ ] Unique cert per kiosk
- [ ] Cert revocation process
- [ ] Secure storage of private keys
- [ ] Restrict broker to only required topics
- [ ] Dashboard auth (admin login)

## Open Questions
- VPS details (provider, OS, domain)
- Preferred language/stack for agent + dashboard
- Desired update window time per kiosk
- Command execution policy (whitelist vs full shell)

## Notes
- Debian 13 kiosks use Python 3.13.
- Chromium built-in touch keyboard doesn’t auto-show on Linux; use xvkbd auto-show via AT-SPI focus events.

## Detailed Build-Out (Living Spec)

### 0) Repo Layout (Server + Agent)
Suggested structure (new repo or subfolder):
- `server/`
  - `broker/` (mosquitto config + certs)
  - `controller/` (API + MQTT command publisher)
  - `dashboard/` (UI)
  - `data/` (sqlite/db backups)
- `agent/`
  - `agent.py` (or Go binary)
  - `systemd/` (service + timer)
  - `scripts/` (update runner)
  - `config/` (sample config + cert paths)

### 1) Identity + mTLS Plan
- Create internal CA (offline stored).
- One client cert per kiosk:
  - CN = kiosk_id (e.g., `kiosk-nyc-01`)
  - store at `/etc/kiosk-agent/certs/`
- Server cert signed by same CA.
- Mosquitto configured to:
  - require client certs
  - map CN to ACL topics

### 2) MQTT Topics + Payloads (Draft)
Topics:
- `kiosk/<id>/status` (heartbeat)
- `kiosk/<id>/cmd` (commands from server)
- `kiosk/<id>/reply` (command results)

Heartbeat payload (JSON):
```
{
  "kiosk_id": "kiosk-nyc-01",
  "location": "NYC - 5th Ave",
  "last_seen": "2026-01-30T03:00:00Z",
  "uptime_sec": 123456,
  "ip": "203.0.113.10",
  "git_sha": "a4a35bb",
  "os_version": "Debian 13",
  "services": { "kiosk-session": "active", "kiosk-ui": "active" },
  "last_update": { "status": "success", "ts": "2026-01-29T03:30:00Z" }
}
```

Command payload:
```
{
  "cmd_id": "uuid",
  "action": "update_full | update_os | update_repo | run_install | restart_services | reboot | shell",
  "when": "immediate | nightly",
  "args": {}
}
```

Reply payload:
```
{
  "cmd_id": "uuid",
  "status": "success | failed",
  "started_at": "…",
  "finished_at": "…",
  "output": "last 4k of logs"
}
```

### 3) Kiosk Agent Responsibilities
- Load config (`/etc/kiosk-agent/config.json`)
- Connect to MQTT with mTLS
- Send heartbeat every 30–60s
- Subscribe to `kiosk/<id>/cmd`
- Queue commands for nightly run
- Execute update runner + return results

### 4) Update Runner (Kiosk)
Actions:
- `update_os`: `apt update && apt upgrade -y`
- `update_repo`: `git -C /path/to/repo pull`
- `run_install`: `SKIP_APT=1 ./install.sh`
- `restart_services`: `systemctl --user restart kiosk-session.service kiosk-ui.service`
- `reboot`: `systemctl reboot`

### 5) Nightly Scheduler (Kiosk)
- systemd timer at kiosk-specific time
- runs queued jobs in order
- posts result summary on completion

### 6) Reverse SSH (Remote Shell)
- Each kiosk runs autossh to VPS:
  - `autossh -M 0 -N -R <port>:localhost:22 <user>@<server>`
- Port map table stored in dashboard
- Access: `ssh -p <port> <kiosk_user>@<server>`

### 7) Dashboard (MVP)
Screens:
- Overview list: status, location, last_seen, git_sha, os_version
- Kiosk detail: logs, command history, schedule
- Actions: update_os, update_repo, update_full, reboot, open shell

### 8) Rollback Strategy
- Store last known good git SHA in `/var/lib/kiosk-agent/last_good`
- If update fails, rollback:
  - `git reset --hard <last_good>`
  - `./install.sh`
  - restart services

### 9) Logging + Auditing
- Persist command logs per kiosk
- Dashboard shows who triggered updates and results
- Rotate logs weekly (retain 30–90 days)

## Step-by-Step Build Plan (Detailed)

### Server Build (VPS)
1. Provision VPS (Debian/Ubuntu).
2. Install Mosquitto + enable TLS.
3. Create CA + server certs.
4. Configure Mosquitto ACL by kiosk CN.
5. Deploy controller (API + MQTT publisher).
6. Deploy dashboard (UI + DB).

### Kiosk Build
1. Install agent package + config.
2. Install client certs.
3. Enable agent service + timer.
4. Configure reverse SSH.
5. Verify heartbeat in dashboard.

## Handoff Notes for New Contributors
- Keep all secrets in `/etc/kiosk-agent/` (never in repo).
- Any new command must include:
  - validation
  - logging
  - result reporting
- Prefer idempotent scripts.

