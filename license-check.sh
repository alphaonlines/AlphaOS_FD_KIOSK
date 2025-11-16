#!/bin/bash

LICENSE_URL="https://yourwebsite.com/license/kiosk-license.txt"
LOG_FILE="/var/log/license-check.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> $LOG_FILE
}

# Function to check license
check_license() {
    log_message "Starting license check..."
    
    # Attempt to reach the license endpoint directly rather than relying on ICMP reachability.
    if curl -f -s --connect-timeout 10 --max-time 30 "$LICENSE_URL" >/dev/null 2>&1; then
        log_message "License check: VALID"
        return 0
    fi

    status=$?
    case $status in
        6|7|28|35|56)
            log_message "License check: Network unavailable or TLS handshake failed (curl exit $status) - allowing grace period"
            return 0
            ;;
        22)
            log_message "License check: FAILED - License file returned HTTP error"
            return 1
            ;;
        *)
            log_message "License check: FAILED - Unexpected curl status $status"
            return 1
            ;;
    esac
}

# Main execution
check_license
exit $?
