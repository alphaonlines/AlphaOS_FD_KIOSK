#!/bin/bash

# Wait for X server to be ready
sleep 2

LOG_FILE="/var/log/touch-config.log"
DEVICE_PATTERN="${TOUCH_DEVICE_PATTERN:-touch}"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
}

set_if_supported() {
    local device_id=$1
    local prop=$2
    shift 2

    if xinput list-props "$device_id" | grep -Fq "$prop"; then
        xinput set-prop "$device_id" "$prop" "$@"
        return 0
    fi

    log_message "Property '$prop' not supported on device $device_id"
    return 1
}

mapfile -t TOUCH_DEVICES < <(xinput list | grep -i "$DEVICE_PATTERN" | grep -o 'id=[0-9]*' | cut -d'=' -f2)

if [ ${#TOUCH_DEVICES[@]} -eq 0 ]; then
    log_message "No touch device found matching pattern '$DEVICE_PATTERN'"
    exit 0
fi

for TOUCH_DEVICE in "${TOUCH_DEVICES[@]}"; do
    log_message "Configuring touch device: $TOUCH_DEVICE"
    set_if_supported "$TOUCH_DEVICE" "libinput Natural Scrolling Enabled" 1
    set_if_supported "$TOUCH_DEVICE" "libinput Tapping Enabled" 1
    set_if_supported "$TOUCH_DEVICE" "libinput Scroll Method Enabled" 0 0 0
    log_message "Touch device configured: $TOUCH_DEVICE"
    # Configure only the first matching device; adjust if multiple devices need handling.
    break
done
