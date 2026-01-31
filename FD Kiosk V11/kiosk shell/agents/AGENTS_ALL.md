# Kiosk Shell Agents (Consolidated)

This file combines the individual agent briefs and TODOs for the kiosk shell MVP.

## Agent: PM/Integrator — Project Manager (You + Me)

### Role
Own the project plan, keep deliverables aligned, and integrate components into a working system.

### Scope
- Maintain architecture and schema alignment.
- Track dependencies and unblock engineers.
- Integrate agent + broker/controller + dashboard into a runnable stack.
- Define acceptance tests for end-to-end flow.

### Deliverables
- A consolidated `INTEGRATION.md` with runbook steps.
- A shared schema doc for MQTT payloads and API endpoints.
- Integration checklist and test script (manual ok).

### Expectations
- Weekly checkpoints with Dev 1–3.
- Resolve schema conflicts quickly.
- Keep scope trimmed to MVP.

### Current Focus (Updated)
- Drive an end-to-end smoke test (broker → controller → agent → dashboard).
- Record any schema deviations and update `SCHEMA.md`.
- Verify nightly schedule decisions and update systemd timer as needed.

## Agent: Dev 1 — Kiosk Agent (Heartbeat + Command Queue)

### Role
Build the kiosk-side agent that connects to MQTT with mTLS, emits heartbeats, receives commands, queues nightly jobs, and reports results.

### Scope
- Implement a minimal Python agent (Debian 13 / Python 3.13) that:
  - Loads config from `/etc/kiosk-agent/config.json` (create sample in `agent/config/`).
  - Connects to MQTT over mTLS.
  - Publishes heartbeat JSON every 30–60 seconds.
  - Subscribes to `kiosk/<id>/cmd` and enqueues commands.
  - Executes queued jobs at a nightly time (local systemd timer ok).
  - Posts command results to `kiosk/<id>/reply`.
- Provide a simple update runner script in `agent/scripts/`.

### Deliverables
- `agent/agent.py` (or structured package under `agent/`).
- `agent/config/config.sample.json` with required fields.
- `agent/scripts/update_runner.sh` and any helper scripts.
- `agent/systemd/kiosk-agent.service` and `agent/systemd/kiosk-agent.timer` (or clear instructions if timer is separate).
- README notes for install/run in `agent/`.

### Constraints
- Must be idempotent and resilient to restarts.
- Log to stdout and to a file under `/var/lib/kiosk-agent/`.
- Do not hardcode secrets or paths other than standard locations.
- Keep dependencies minimal (prefer `paho-mqtt`).

### Definition of Done
- Agent can run locally and simulate heartbeats and command replies.
- Queued commands execute at the scheduled window.
- Clear install steps and config template are provided.

### Progress (Implemented)
- MQTT agent with mTLS, heartbeat loop, command handling, and nightly queue runner.
- Update runner script and systemd service/timer units.
- Heartbeat telemetry expanded: disk usage, memory usage, CPU load averages, disk IO counters.

### TODO / Decisions Needed (as of Jan 30, 2026)
- **Click/usage count source:** Decide how the agent should detect touches (app-emitted file/counter, OS input events, or helper service). Provide path/format for 5‑minute debounce counting.
- **Nightly schedule time:** Confirm per‑kiosk time (systemd timer currently set to 03:00 local).
- **MQTT broker details:** Confirm host/port and cert paths for production.
- **Repo path + service names:** Confirm actual kiosk app path and service unit names.
- **Install layout:** Confirm final paths for agent files and update runner (currently `/opt/kiosk-agent` and `/usr/local/lib/kiosk-agent`).

### Coordination
- Coordinate MQTT topic names and payload schema with Dev 2 (server/broker).
- Coordinate dashboard fields with Dev 3 (dashboard/API).

### Current Focus (Updated)
- Ensure queued jobs are not lost during nightly runs (atomic queue drain + re-append failures).
- Add a run lock so immediate and nightly updates never overlap.
- Keep `SCHEMA.md` aligned with any telemetry fields you emit.

## Agent: Dev 2 — Server/Broker + mTLS + Command API

### Role
Stand up the secure MQTT broker with mTLS and provide a minimal controller API to publish commands and receive replies.

### Scope
- Mosquitto configuration for mTLS and ACLs.
- Internal CA generation flow and cert layout.
- Minimal controller service to:
  - Publish commands to `kiosk/<id>/cmd`.
  - Subscribe to `kiosk/+/reply` and persist results.
  - Track last_seen heartbeats.

### Deliverables
- `server/broker/mosquitto.conf` and ACL file template.
- `server/broker/certs/README.md` with steps for CA + cert generation.
- `server/controller/` with a small service (language of choice, prefer Python Flask or Node).
- Simple persistence (sqlite in `server/data/`).
- README notes for running locally.

### Constraints
- Require client certs, map CN to kiosk ID.
- Topics restricted to kiosk-specific paths.
- No hardcoded cert paths; use config file or env vars.

### Definition of Done
- Broker accepts mTLS client certs and rejects unauthorized clients.
- Controller can publish a command and record a reply.
- Heartbeat updates last_seen per kiosk.

### Coordination
- Align payload schema with Dev 1.
- Provide API endpoints that Dev 3 can call.

### Current Status (2026-01-30)
- Broker mTLS config + ACLs in place.
- Cert generation guide documented.
- Controller validates command payloads and handles publish failures.
- Agent handles missing update runner path gracefully.

### Current Focus (Updated)
- Validate mTLS connectivity with real certs (controller + one kiosk).
- Run end-to-end smoke test: command publish → kiosk reply → dashboard history.
- Confirm broker paths/ports for deployment environment.

## Agent: Dev 3 — Dashboard MVP (Status + Actions)

### Role
Build the minimal dashboard UI and API integration to view kiosk status and trigger commands.

### Scope
- Simple web UI (framework of choice) that shows:
  - Kiosk list with status, location, last_seen, os_version, git_sha.
  - Kiosk detail page with command history.
- Actions: update_os, update_repo, update_full, reboot.
- Integrate with controller API from Dev 2.

### Deliverables
- `server/dashboard/` app (UI + minimal API client).
- Clear instructions for running locally.
- Minimal styling with readable status indicators.

### Constraints
- Focus on MVP; no auth yet (stub only).
- Avoid complex state management.

### Definition of Done
- Dashboard loads kiosk list from API.
- Action button triggers a command and shows result history.

### Coordination
- Confirm API shape and endpoints with Dev 2.

### Status (2026-01-30)
- Confirmed Dev 2 controller API endpoints and payload shape.
- Implemented dashboard MVP in `server/dashboard/`:
  - Flask app proxying controller API.
  - Kiosk list + detail views.
  - Action buttons for update_os/update_repo/update_full/reboot.
  - Minimal styling and JS client logic.
  - README with local run steps.

### TODO
- Smoke-test dashboard against a running controller instance.
- Tweak status thresholds or fields if product wants different online/stale/offline logic.
- Add simple auth stub if requested (placeholder only).

### Current Focus (Updated)
- Verify dashboard behavior when controller returns publish_failed errors.
- Confirm history table renders large output gracefully (truncate if needed).

## Dev 2 TODO (Snapshot)

### Done
- Broker mTLS config (`server/broker/mosquitto.conf`).
- Broker ACL template (`server/broker/acl.conf`).
- CA + cert generation guide (`server/broker/certs/README.md`).
- Controller command validation + publish failure handling.
- Agent handles missing update runner path gracefully.

### Next
- Confirm broker paths/ports in deploy environment.
- Validate controller mTLS connectivity against broker.
- End-to-end command + reply smoke test with a kiosk cert.
- Decide controller HTTP auth (shared token vs mTLS vs none).
- Decide kiosk_id validation rules (prefix, length, allowed chars).
