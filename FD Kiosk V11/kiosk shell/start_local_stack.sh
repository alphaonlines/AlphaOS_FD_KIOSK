#!/usr/bin/env bash
set -e

mkdir -p /home/fduser/kiosk-agent

nohup env LD_LIBRARY_PATH="/home/fduser/tmp_mosq/mosqroot/usr/lib/x86_64-linux-gnu" \
  "/home/fduser/tmp_mosq/mosqroot/usr/sbin/mosquitto" \
  -c "/home/fduser/Desktop/FD Kiosk V11/kiosk shell/server/broker/mosquitto.local.conf" -v \
  > /home/fduser/kiosk-agent/mosquitto.log 2>&1 &
echo $! > /home/fduser/kiosk-agent/mosquitto.pid

nohup env PYTHONPATH="/home/fduser/tmp_pydeps/root/usr/lib/python3/dist-packages" \
  python3 "/home/fduser/Desktop/FD Kiosk V11/kiosk shell/server/controller/app.py" \
  > /home/fduser/kiosk-agent/controller.log 2>&1 &
echo $! > /home/fduser/kiosk-agent/controller.pid

nohup env PYTHONPATH="/home/fduser/tmp_pydeps/root/usr/lib/python3/dist-packages" \
  python3 "/home/fduser/Desktop/FD Kiosk V11/kiosk shell/server/dashboard/app.py" \
  > /home/fduser/kiosk-agent/dashboard.log 2>&1 &
echo $! > /home/fduser/kiosk-agent/dashboard.pid

nohup env PYTHONPATH="/home/fduser/tmp_pydeps/root/usr/lib/python3/dist-packages" \
  python3 "/home/fduser/Desktop/FD Kiosk V11/kiosk shell/agent/agent.py" \
  --config "/home/fduser/Desktop/FD Kiosk V11/kiosk shell/agent/config/config.json" \
  > /home/fduser/kiosk-agent/agent.log 2>&1 &
echo $! > /home/fduser/kiosk-agent/agent.pid

echo "Local stack started."
