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
sudo cp .bash_profile /home/kiosk/
sudo cp .xinitrc /home/kiosk/
sudo cp alpha-kiosk.plymouth /lib/plymouth/themes/alpha-kiosk/
sudo cp alpha-kiosk.script /lib/plymouth/themes/alpha-kiosk/

# Set permissions
echo "Setting permissions..."
sudo chmod +x /usr/local/bin/license-check.sh
sudo chmod +x /usr/local/bin/touch-config.sh
chmod +x /home/kiosk/.xinitrc
chown kiosk:kiosk /home/kiosk/.xinitrc
chown kiosk:kiosk /home/kiosk/.bash_profile

# Configure auto-login trigger
echo "Configuring auto-login..."
chown kiosk:kiosk /home/kiosk/.bash_profile

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
echo "Don't forget to:"
echo "1. Copy your splash.png to /lib/plymouth/themes/alpha-kiosk/"
echo "2. Update URLs in /home/kiosk/.xinitrc"
echo "3. Update LICENSE_URL in /usr/local/bin/license-check.sh"
