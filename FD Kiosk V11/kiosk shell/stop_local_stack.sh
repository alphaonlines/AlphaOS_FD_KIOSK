#!/usr/bin/env bash
set -e

for pidfile in /home/fduser/kiosk-agent/*.pid; do
  if [[ -f "$pidfile" ]]; then
    pid=$(cat "$pidfile" 2>/dev/null || true)
    if [[ -n "${pid}" ]]; then
      kill "$pid" 2>/dev/null || true
    fi
  fi
done

rm -f /home/fduser/kiosk-agent/*.pid
echo "Local stack stopped."
