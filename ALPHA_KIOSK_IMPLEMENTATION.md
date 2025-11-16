# AlphaOS Kiosk Implementation Guide

## Overview
This guide creates a custom Ubuntu-based kiosk system with:
- Auto-login to kiosk mode
- Online license validation
- Touch screen support
- Custom branding
- No desktop environment

## Prerequisites
- Ubuntu Server 22.04 LTS installation media
- Access to license file on your website
- Admin rights on target machines
- Custom splash image (1920x1080.png)

---

## Phase 1: Base System Installation

### 1.1 Install Ubuntu Server 22.04 LTS
1. Download Ubuntu Server 22.04 LTS from ubuntu.com
2. Create bootable USB using Rufus (Windows) or `dd` (Linux)
3. Boot from USB and install minimal system
4. During installation:
   - Set hostname: `alpha-kiosk`
   - Create user: `kiosk`
   - Install OpenSSH server (optional)
   - No additional software packages

### 1.2 Initial System Setup
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y xorg x11-xserver-utils firefox onboard network-manager plymouth plymouth-themes unclutter xinput-calibrator touchscreen-tools

# Install system utilities
sudo apt install -y curl wget htop vim
```

---

## Phase 2: Auto-Login Configuration

### 2.1 Configure Auto-Login
```bash
# Create autologin configuration
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo nano /etc/systemd/system/getty@tty1.service.d/autologin.conf
```

**Add this content to autologin.conf:**
```ini
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin kiosk --noclear %I $TERM
```

### 2.2 Configure Auto-Start X Server
```bash
# Create .bash_profile for kiosk user (runs only on tty1 login)
cat <<'EOF' | sudo tee /home/kiosk/.bash_profile
#!/bin/bash

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF
sudo chown kiosk:kiosk /home/kiosk/.bash_profile
sudo chmod 644 /home/kiosk/.bash_profile
```

Using `.bash_profile` keeps the auto-start logic idempotent and scoped to the auto-login terminal so repeated deployments will not duplicate the block.

---

## Phase 3: Kiosk Browser Configuration

### 3.1 Create X Session
```bash
# Create .xinitrc for kiosk user
nano /home/kiosk/.xinitrc
```

**Add this content to .xinitrc:**
```bash
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
```

The loop ensures Firefox restarts automatically if it crashes, and `/var/log/kiosk-session.log` records exit codes for troubleshooting.

### 3.2 Make .xinitrc Executable
```bash
chmod +x /home/kiosk/.xinitrc
chown kiosk:kiosk /home/kiosk/.xinitrc
```

---

## Phase 4: Licensing System

### 4.1 Create License Check Script
```bash
sudo nano /usr/local/bin/license-check.sh
```

**Add this content to license-check.sh:**
```bash
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
    
    # Attempt to reach the license endpoint directly rather than relying on ping.
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
```

This version distinguishes between HTTP failures (invalid license) and transient network/TLS problems, so kiosks follow a predictable grace-period path even if ICMP is blocked.

### 4.2 Create Touch Configuration Script
```bash
sudo nano /usr/local/bin/touch-config.sh
```

**Add this content to touch-config.sh:**
```bash
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
    break
done
```

Set the optional environment variable `TOUCH_DEVICE_PATTERN` (e.g., `TOUCH_DEVICE_PATTERN="elan"`) to match specific hardware models when multiple digitizers are present.

### 4.3 Make Scripts Executable
```bash
sudo chmod +x /usr/local/bin/license-check.sh
sudo chmod +x /usr/local/bin/touch-config.sh
```

---

## Phase 5: Custom Branding

### 5.1 Prepare Custom Splash Screen
1. Create or obtain a 1920x1080 PNG image for your splash screen
2. Name it `splash.png`
3. Copy it to the system:
```bash
sudo mkdir -p /lib/plymouth/themes/alpha-kiosk
sudo cp splash.png /lib/plymouth/themes/alpha-kiosk/
```

### 5.2 Create Plymouth Theme
```bash
sudo nano /lib/plymouth/themes/alpha-kiosk/alpha-kiosk.plymouth
```

**Add this content:**
```ini
[Plymouth Theme]
Name=Alpha Kiosk
Description=Custom Alpha Kiosk Theme
ModuleName=script

[script]
ImageDir=/lib/plymouth/themes/alpha-kiosk
ScriptFile=/lib/plymouth/themes/alpha-kiosk/alpha-kiosk.script
```

### 5.3 Create Plymouth Script
```bash
sudo nano /lib/plymouth/themes/alpha-kiosk/alpha-kiosk.script
```

**Add this content:**
```bash
splash_image = Image("splash.png");

# Get screen dimensions
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();

# Get image dimensions
image_width = splash_image.GetWidth();
image_height = splash_image.GetHeight();

# Center the image
splash_image.SetPosition(screen_width / 2 - image_width / 2, 
                        screen_height / 2 - image_height / 2);

# Scale image if needed
if (image_width > screen_width || image_height > screen_height) {
    scale_factor = Math.Min(screen_width / image_width, screen_height / image_height);
    scaled_width = image_width * scale_factor;
    scaled_height = image_height * scale_factor;
    splash_image.SetScale(scaled_width, scaled_height);
    splash_image.SetPosition(screen_width / 2 - scaled_width / 2, 
                            screen_height / 2 - scaled_height / 2);
}
```

### 5.4 Activate Custom Theme
```bash
sudo update-alternatives --install /lib/plymouth/themes/default.plymouth default.plymouth /lib/plymouth/themes/alpha-kiosk/alpha-kiosk.plymouth 100
sudo update-alternatives --set default.plymouth /lib/plymouth/themes/alpha-kiosk/alpha-kiosk.plymouth
sudo update-initramfs -u
```

---

## Phase 6: System Hardening

### 6.1 Disable Unnecessary Services
```bash
sudo systemctl disable bluetooth
sudo systemctl disable cups
sudo systemctl disable avahi-daemon
sudo systemctl disable snapd
```

### 6.2 Configure Firewall
```bash
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow out 80/tcp
sudo ufw allow out 443/tcp
sudo ufw allow out 53/udp
sudo ufw --force enable
```

Review additional outbound requirements (NTP, remote support, mirrors, etc.) and explicitly allow those ports before enabling UFW to avoid starving the kiosk of necessary services.

### 6.3 Set Up Automatic Security Updates
```bash
sudo apt install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## Phase 7: Testing & Validation

### 7.1 Test Checklist
- [ ] System boots without errors
- [ ] Auto-login works (no password prompt)
- [ ] Custom splash screen displays during boot
- [ ] License check runs successfully
- [ ] Firefox starts in kiosk mode
- [ ] Touch screen responds correctly
- [ ] On-screen keyboard appears when needed
- [ ] System reboots properly

### 7.2 Manual Testing Commands
```bash
# Test license check manually
sudo /usr/local/bin/license-check.sh
echo $?

# Check logs
tail -f /var/log/license-check.log
tail -f /var/log/touch-config.log

# Test X session manually
sudo -u kiosk startx -- :1
```

---

## Phase 8: Deployment

### 8.1 Create Deployment Script
```bash
nano deploy-kiosk.sh
```

**Add this content:**
```bash
#!/bin/bash

# Alpha Kiosk Deployment Script
# Run this script after Ubuntu Server installation

set -e

echo "Starting Alpha Kiosk deployment..."

# Update system
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Install packages
echo "Installing required packages..."
sudo apt install -y xorg x11-xserver-utils firefox onboard network-manager plymouth plymouth-themes unclutter xinput-calibrator touchscreen-tools curl wget htop

# Create directories
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo mkdir -p /lib/plymouth/themes/alpha-kiosk

# Copy configuration files (assuming they're in the same directory)
echo "Setting up configuration files..."
sudo cp autologin.conf /etc/systemd/system/getty@tty1.service.d/
sudo cp license-check.sh /usr/local/bin/
sudo cp touch-config.sh /usr/local/bin/
sudo cp .xinitrc /home/kiosk/
sudo cp alpha-kiosk.plymouth /lib/plymouth/themes/alpha-kiosk/
sudo cp alpha-kiosk.script /lib/plymouth/themes/alpha-kiosk/

# Set permissions
echo "Setting permissions..."
sudo chmod +x /usr/local/bin/license-check.sh
sudo chmod +x /usr/local/bin/touch-config.sh
chmod +x /home/kiosk/.xinitrc
chown kiosk:kiosk /home/kiosk/.xinitrc

# Configure auto-login
echo "Configuring auto-login..."
echo 'if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi' >> /home/kiosk/.bashrc

# Configure Plymouth theme
echo "Setting up custom splash screen..."
sudo update-alternatives --install /lib/plymouth/themes/default.plymouth default.plymouth /lib/plymouth/themes/alpha-kiosk/alpha-kiosk.plymouth 100
sudo update-alternatives --set default.plymouth /lib/plymouth/themes/alpha-kiosk/alpha-kiosk.plymouth
sudo update-initramfs -u

# Configure firewall
echo "Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow out 80/tcp
sudo ufw allow out 443/tcp
sudo ufw allow out 53/udp
sudo ufw --force enable

# Disable unnecessary services
echo "Disabling unnecessary services..."
sudo systemctl disable bluetooth cups avahi-daemon snapd

echo "Deployment complete! Reboot to start kiosk mode."
```

### 8.2 Make Deployment Script Executable
```bash
chmod +x deploy-kiosk.sh
```

---

## Phase 9: Maintenance

### 9.1 Log Files to Monitor
- `/var/log/license-check.log` - License validation attempts
- `/var/log/touch-config.log` - Touch screen configuration
- `/var/log/syslog` - System logs
- `/var/log/auth.log` - Authentication logs

### 9.2 Regular Maintenance Tasks
```bash
# Check license validation logs
tail -20 /var/log/license-check.log

# Check system status
systemctl status

# Update system
sudo apt update && sudo apt upgrade -y

# Check disk space
df -h

# Check memory usage
free -h
```

---

## Troubleshooting

### Common Issues

**Auto-login not working:**
```bash
# Check autologin configuration
cat /etc/systemd/system/getty@tty1.service.d/autologin.conf
sudo systemctl daemon-reload
sudo systemctl restart getty@tty1
```

**Touch screen not working:**
```bash
# List input devices
xinput list

# Test touch configuration
sudo /usr/local/bin/touch-config.sh
```

**License check failing:**
```bash
# Test internet connectivity
ping 8.8.8.8

# Test license URL manually
curl -v https://yourwebsite.com/license/kiosk-license.txt
```

**Firefox not starting:**
```bash
# Check X server logs
cat /home/kiosk/.xsession-errors

# Test Firefox manually
firefox --version
```

---

## File Structure Summary
```
/etc/systemd/system/getty@tty1.service.d/
└── autologin.conf

/home/kiosk/
├── .bash_profile
├── .bashrc
└── .xinitrc

/usr/local/bin/
├── license-check.sh
└── touch-config.sh

/lib/plymouth/themes/alpha-kiosk/
├── alpha-kiosk.plymouth
├── alpha-kiosk.script
└── splash.png

/var/log/
├── license-check.log
├── touch-config.log
└── kiosk-session.log
```

---

## Next Steps

1. **Customize URLs**: Replace `https://your-kiosk-app.com` and `https://yourwebsite.com` with your actual URLs
2. **Add splash image**: Copy your custom `splash.png` to `/lib/plymouth/themes/alpha-kiosk/`
3. **Test thoroughly**: Run through the testing checklist
4. **Deploy to devices**: Use the deployment script for multiple machines
5. **Monitor**: Set up regular monitoring of the log files

---

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review log files in `/var/log/`
3. Test components individually using the manual testing commands
4. Ensure all URLs and file paths are correct for your environment
