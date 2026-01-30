# Agent: Dev 3 — Dashboard MVP (Status + Actions)

## Role
Build the minimal dashboard UI and API integration to view kiosk status and trigger commands.

## Scope
- Simple web UI (framework of choice) that shows:
  - Kiosk list with status, location, last_seen, os_version, git_sha.
  - Kiosk detail page with command history.
- Actions: update_os, update_repo, update_full, reboot.
- Integrate with controller API from Dev 2.

## Deliverables
- `server/dashboard/` app (UI + minimal API client).
- Clear instructions for running locally.
- Minimal styling with readable status indicators.

## Constraints
- Focus on MVP; no auth yet (stub only).
- Avoid complex state management.

## Definition of Done
- Dashboard loads kiosk list from API.
- Action button triggers a command and shows result history.

## Coordination
- Confirm API shape and endpoints with Dev 2.

## Status (2026-01-30)
- Confirmed Dev 2 controller API endpoints and payload shape.
- Implemented dashboard MVP in `server/dashboard/`:
  - Flask app proxying controller API.
  - Kiosk list + detail views.
  - Action buttons for update_os/update_repo/update_full/reboot.
  - Minimal styling and JS client logic.
  - README with local run steps.

## TODO
- Smoke-test dashboard against a running controller instance.
- Tweak status thresholds or fields if product wants different online/stale/offline logic.
- Add simple auth stub if requested (placeholder only).

## Current Focus (Updated)
- Verify dashboard behavior when controller returns publish_failed errors.
- Confirm history table renders large output gracefully (truncate if needed).
