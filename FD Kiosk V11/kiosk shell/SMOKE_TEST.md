# Kiosk Shell Smoke Test (Local)

This verifies broker → controller → agent → reply.

## 1) Start the stack
```bash
./kiosk\ shell/start_local_stack.sh
```

## 2) Confirm heartbeat
```bash
curl -s http://127.0.0.1:8080/api/kiosks
```
Expected: kiosk list with `kiosk-001` and a recent `last_seen`.

## 3) Send a command
```bash
/home/fduser/send_cmd.sh kiosk-001 restart_services immediate
```
Expected: `{"cmd_id":"..."}`.

## 4) Check history
```bash
curl -s http://127.0.0.1:8080/api/kiosks/kiosk-001/history
```
Expected: most recent entry shows `restart_services` with `status` and timestamps.

## 5) Optional UI check
Open: `http://127.0.0.1:8090`

## 6) Stop the stack
```bash
./kiosk\ shell/stop_local_stack.sh
```

## Docker (optional)
If using docker-compose:
```bash
cd "/home/fduser/Desktop/FD Kiosk V11/kiosk shell"
docker compose up -d
```

## Logs
```
/home/fduser/kiosk-agent/mosquitto.log
/home/fduser/kiosk-agent/controller.log
/home/fduser/kiosk-agent/dashboard.log
/home/fduser/kiosk-agent/agent.log
```
