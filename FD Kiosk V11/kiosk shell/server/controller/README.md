# Controller Service (MVP)

## Setup
1) Copy `config.sample.json` to `config.json` and update paths.
   - For production, start from `config.prod.sample.json`.
2) Install deps: `pip install -r requirements.txt`.
3) Run: `python app.py`.

## Docker
```bash
docker build -t kiosk-controller .
docker run --rm -p 8080:8080 kiosk-controller
```

## API
- `GET /api/kiosks`
- `GET /api/kiosks/<id>/history`
- `POST /api/command`

## Notes
- MQTT uses mTLS; ensure controller certs are valid.
- Database: sqlite at `server/data/controller.db` by default.
- Production checklist: `../../PRODUCTION_CHECKLIST.md`
