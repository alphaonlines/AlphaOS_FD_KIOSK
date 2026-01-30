# Dashboard (MVP)

Minimal web UI for kiosk status + command actions. Proxies requests to the controller API to avoid CORS issues.

## Setup
1) Copy `config.sample.json` to `config.json` and update controller base URL.
2) Install deps: `pip install -r requirements.txt`.
3) Run: `python app.py`.

## Usage
- Open `http://localhost:8090` (or the configured port).
- Click a kiosk to view history and issue commands.

## Notes
- Controller must be running and reachable at the configured `controller.base_url`.
- Actions supported: `update_os`, `update_repo`, `update_full`, `reboot`.
