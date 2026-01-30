# Agent: Dev 1 — Kiosk Agent (Heartbeat + Command Queue)

## Role
Build the kiosk-side agent that connects to MQTT with mTLS, emits heartbeats, receives commands, queues nightly jobs, and reports results.

## Scope
- Implement a minimal Python agent (Debian 13 / Python 3.13) that:
  - Loads config from `/etc/kiosk-agent/config.json` (create sample in `agent/config/`).
  - Connects to MQTT over mTLS.
  - Publishes heartbeat JSON every 30–60 seconds.
  - Subscribes to `kiosk/<id>/cmd` and enqueues commands.
  - Executes queued jobs at a nightly time (local systemd timer ok).
  - Posts command results to `kiosk/<id>/reply`.
- Provide a simple update runner script in `agent/scripts/`.

## Deliverables
- `agent/agent.py` (or structured package under `agent/`).
- `agent/config/config.sample.json` with required fields.
- `agent/scripts/update_runner.sh` and any helper scripts.
- `agent/systemd/kiosk-agent.service` and `agent/systemd/kiosk-agent.timer` (or clear instructions if timer is separate).
- README notes for install/run in `agent/`.

## Constraints
- Must be idempotent and resilient to restarts.
- Log to stdout and to a file under `/var/lib/kiosk-agent/`.
- Do not hardcode secrets or paths other than standard locations.
- Keep dependencies minimal (prefer `paho-mqtt`).

## Definition of Done
- Agent can run locally and simulate heartbeats and command replies.
- Queued commands execute at the scheduled window.
- Clear install steps and config template are provided.

## Progress (Implemented)
- MQTT agent with mTLS, heartbeat loop, command handling, and nightly queue runner.
- Update runner script and systemd service/timer units.
- Heartbeat telemetry expanded: disk usage, memory usage, CPU load averages, disk IO counters.

## TODO / Decisions Needed (as of Jan 30, 2026)
- **Click/usage count source:** Decide how the agent should detect touches (app-emitted file/counter, OS input events, or helper service). Provide path/format for 5‑minute debounce counting.
- **Nightly schedule time:** Confirm per‑kiosk time (systemd timer currently set to 03:00 local).
- **MQTT broker details:** Confirm host/port and cert paths for production.
- **Repo path + service names:** Confirm actual kiosk app path and service unit names.
- **Install layout:** Confirm final paths for agent files and update runner (currently `/opt/kiosk-agent` and `/usr/local/lib/kiosk-agent`).

## Coordination
- Coordinate MQTT topic names and payload schema with Dev 2 (server/broker).
- Coordinate dashboard fields with Dev 3 (dashboard/API).

## Current Focus (Updated)
- Ensure queued jobs are not lost during nightly runs (atomic queue drain + re-append failures).
- Add a run lock so immediate and nightly updates never overlap.
- Keep `SCHEMA.md` aligned with any telemetry fields you emit.
