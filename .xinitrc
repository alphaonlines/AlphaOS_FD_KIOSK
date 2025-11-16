#!/bin/bash

# Disable screen saver and power management
xset s off
xset -dpms
xset s noblank

# Hide mouse cursor after inactivity
unclutter -idle 0.5 -root &

# Configure touch screen
/usr/local/bin/touch-config.sh &

# Start on-screen keyboard
onboard --daemon &

# Wait for network connection
sleep 5

while true; do
    # Check license before starting kiosk
    if /usr/local/bin/license-check.sh; then
        # License valid - start kiosk
        firefox --kiosk "https://your-kiosk-app.com"
        EXIT_CODE=$?
        echo "Firefox exited with code $EXIT_CODE, restarting kiosk session..." >> /var/log/kiosk-session.log 2>&1
        sleep 2
    else
        # License invalid - show renewal page then power down
        firefox --kiosk "https://yourwebsite.com/renew.html"
        sleep 10
        shutdown -h now
        break
    fi
done
