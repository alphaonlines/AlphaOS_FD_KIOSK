# Dashboard (MVP)

Minimal web UI for kiosk status + command actions. Proxies requests to the controller API to avoid CORS issues.

## Setup
1) Copy `config.sample.json` to `config.json` and update controller base URL.
   - For production, start from `config.prod.sample.json`.
2) Install deps: `pip install -r requirements.txt`.
3) Run: `python app.py`.

## Docker
```bash
docker build -t kiosk-dashboard .
docker run --rm -p 8090:8090 kiosk-dashboard
```

## Usage
- Open `http://localhost:8090` (or the configured port).
- Click a kiosk to view history and issue commands.

## Notes
- Controller must be running and reachable at the configured `controller.base_url`.
- Actions supported: `update_os`, `update_repo`, `update_full`, `reboot`.
- Production checklist: `../../PRODUCTION_CHECKLIST.md`
