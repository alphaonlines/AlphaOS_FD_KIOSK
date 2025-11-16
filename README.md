# Alpha Kiosk Quick Start

## Files Ready for Deployment

This directory contains all the configuration files and scripts needed to deploy your Alpha Kiosk system.

### Main Files:
- **ALPHA_KIOSK_IMPLEMENTATION.md** - Complete implementation guide
- **deploy-kiosk.sh** - Automated deployment script
- **license-check.sh** - License validation script
- **touch-config.sh** - Touch screen configuration
- **.bash_profile** - Auto-start trigger for kiosk sessions
- **.xinitrc** - X session configuration
- **autologin.conf** - Auto-login configuration
- **alpha-kiosk.plymouth** - Plymouth theme configuration
- **alpha-kiosk.script** - Plymouth splash script

## Quick Deployment Steps:

### 1. Install Ubuntu Server 22.04 LTS
- Download from ubuntu.com
- Install minimal system
- Create user: `kiosk`

### 2. Copy Files to Target System
```bash
# Copy all files to the target system
scp -r /path/to/Kiosk/ user@target:/home/kiosk/
```

### 3. Run Deployment Script
```bash
cd /home/kiosk/Kiosk
./deploy-kiosk.sh
```

### 4. Add Custom Assets
```bash
# Copy your splash screen (1920x1080.png)
sudo cp your-splash.png /lib/plymouth/themes/alpha-kiosk/splash.png

# Update URLs in configuration files
nano /home/kiosk/.xinitrc
nano /usr/local/bin/license-check.sh
```

### 5. Reboot
```bash
sudo reboot
```

## Before You Deploy:

1. **Update URLs** in:
   - `.xinitrc` (kiosk app URL and renewal URL)
   - `license-check.sh` (license file URL)

2. **Prepare splash screen**:
   - Create 1920x1080 PNG image
   - Name it `splash.png`

3. **Test license file**:
   - Ensure your license file is accessible at the specified URL

## Support:
- See ALPHA_KIOSK_IMPLEMENTATION.md for detailed instructions
- Check troubleshooting section for common issues
