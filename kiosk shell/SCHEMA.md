# Kiosk MQTT + API Schema (MVP)

## MQTT Topics
- `kiosk/<id>/status` — heartbeat from kiosk
- `kiosk/<id>/cmd` — commands from server
- `kiosk/<id>/reply` — command results from kiosk

## Heartbeat Payload (JSON)
Required fields:
- `kiosk_id` (string)
- `location` (string)
- `last_seen` (ISO-8601 UTC)
- `uptime_sec` (int)
- `ip` (string)
- `git_sha` (string)
- `os_version` (string)
- `services` (object)
- `last_update` (object)
Optional telemetry fields:
- `disk` (object)
- `disk_io` (object)
- `memory` (object)
- `load_avg` (object)

Example:
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

## Command Payload (JSON)
Required fields:
- `cmd_id` (string, uuid)
- `action` (string)
- `when` (string: `immediate` or `nightly`)
- `args` (object)

Example:
```
{
  "cmd_id": "uuid",
  "action": "update_full",
  "when": "nightly",
  "args": {}
}
```

Allowed `action` values (MVP):
- `update_full`
- `update_os`
- `update_repo`
- `run_install`
- `restart_services`
- `reboot`

## Reply Payload (JSON)
Required fields:
- `cmd_id` (string)
- `status` (string: `success` or `failed`)
- `started_at` (ISO-8601 UTC)
- `finished_at` (ISO-8601 UTC)
- `output` (string, last 4k logs)

Example:
```
{
  "cmd_id": "uuid",
  "status": "success",
  "started_at": "2026-01-30T03:01:00Z",
  "finished_at": "2026-01-30T03:02:30Z",
  "output": "last 4k of logs"
}
```

## Controller API (MVP)
- `GET /api/kiosks`
  - Returns list of kiosks with last_seen, status, location, os_version, git_sha.
- `GET /api/kiosks/<id>/history`
  - Returns recent command history for kiosk.
- `POST /api/command`
  - Body: `{ kiosk_id, action, when, args }`
  - Returns `{ cmd_id }`
