# Agent: Dev 2 — Server/Broker + mTLS + Command API

## Role
Stand up the secure MQTT broker with mTLS and provide a minimal controller API to publish commands and receive replies.

## Scope
- Mosquitto configuration for mTLS and ACLs.
- Internal CA generation flow and cert layout.
- Minimal controller service to:
  - Publish commands to `kiosk/<id>/cmd`.
  - Subscribe to `kiosk/+/reply` and persist results.
  - Track last_seen heartbeats.

## Deliverables
- `server/broker/mosquitto.conf` and ACL file template.
- `server/broker/certs/README.md` with steps for CA + cert generation.
- `server/controller/` with a small service (language of choice, prefer Python Flask or Node).
- Simple persistence (sqlite in `server/data/`).
- README notes for running locally.

## Constraints
- Require client certs, map CN to kiosk ID.
- Topics restricted to kiosk-specific paths.
- No hardcoded cert paths; use config file or env vars.

## Definition of Done
- Broker accepts mTLS client certs and rejects unauthorized clients.
- Controller can publish a command and record a reply.
- Heartbeat updates last_seen per kiosk.

## Coordination
- Align payload schema with Dev 1.
- Provide API endpoints that Dev 3 can call.

## Current Status (2026-01-30)
- Broker mTLS config + ACLs in place.
- Cert generation guide documented.
- Controller validates command payloads and handles publish failures.
- Agent handles missing update runner path gracefully.

## Current Focus (Updated)
- Validate mTLS connectivity with real certs (controller + one kiosk).
- Run end-to-end smoke test: command publish → kiosk reply → dashboard history.
- Confirm broker paths/ports for deployment environment.
