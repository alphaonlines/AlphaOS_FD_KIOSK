# AlphaOS Kiosk Project - Development Brief

## Project Overview
Creating a custom Linux kiosk system for touch screen deployment on repurposed hardware (Chromeboxes with mrchromebox and All-in-One PCs). The system needs to be branded, licensed, and optimized for touch interaction.

## Requirements Analysis

### Core Requirements
- **Base System**: Ubuntu-based OS with no desktop environment
- **Kiosk Mode**: Auto-login directly to browser in kiosk mode
- **Licensing System**: Online license validation via HTTP file check
- **Touch Support**: Full touch screen optimization with on-screen keyboard
- **Custom Branding**: Custom splash screen and boot branding
- **Hardware**: Chromeboxes (mrchromebox) and All-in-One PCs

### Previous Issues to Resolve
- Scroll wheel/touch scrolling problems
- On-screen keyboard not appearing when clicking search bars
- Touch screen responsiveness issues

## Technical Decisions Made

### Base System Choice
**Selected**: Ubuntu Server 22.04 LTS Minimal
**Reasoning**: 
- Excellent hardware support for Chromeboxes and All-in-Ones
- Long-term support (LTS)
- Good touch screen driver support
- Lightweight for older hardware

### Desktop Environment
**Selected**: No desktop environment - kiosk mode only
**Reasoning**:
- Most lightweight solution
- Most secure (reduced attack surface)
- Faster boot times
- Simplified maintenance

### Licensing Architecture
**Selected**: Simple HTTP file check
**Implementation**:
- License file hosted on company website
- System checks file existence at boot
- Graceful fallback for network issues
- Renewal prompt if license invalid

### Touch Screen Solution
**Selected**: Xorg + libinput + onboard keyboard
**Components**:
- `xinput` for device configuration
- `libinput` for modern touch handling
- `onboard` for on-screen keyboard
- Custom touch configuration script

## Implementation Architecture

### System Components
1. **Boot Process**
   - Custom Plymouth splash screen
   - Auto-login configuration
   - License validation service

2. **Session Management**
   - X server auto-start
   - Touch configuration
   - Kiosk browser launch

3. **Security Hardening**
   - Firewall configuration
   - Service hardening
   - Automatic security updates

### File Structure
```
/etc/systemd/system/getty@tty1.service.d/
└── autologin.conf                    # Auto-login configuration

/home/kiosk/
├── .bash_profile                    # startx trigger scoped to tty1
├── .bashrc                          # shell config
└── .xinitrc                         # Kiosk session script

/usr/local/bin/
├── license-check.sh                 # License validation
└── touch-config.sh                  # Touch configuration

/lib/plymouth/themes/alpha-kiosk/
├── alpha-kiosk.plymouth            # Plymouth theme config
├── alpha-kiosk.script              # Splash screen script
└── splash.png                      # Custom splash image

/var/log/
├── license-check.log               # License validation logs
├── touch-config.log               # Touch configuration logs
└── kiosk-session.log              # Firefox restart log
```

## Key Scripts and Configurations

### License Check Script
- Validates license via direct HTTP request (no dependency on ICMP reachability)
- Handles network connectivity gracefully by inspecting curl exit codes and TLS failures
- Logs all validation attempts
- Returns appropriate exit codes

### Touch Configuration Script
- Detects touch devices automatically with configurable regex pattern
- Configures natural scrolling
- Enables tap-to-click
- Logs device detection and configuration

### Kiosk Session Script (.xinitrc)
- Disables screen saver and power management
- Hides mouse cursor
- Configures touch screen
- Starts on-screen keyboard
- Validates license before launching browser and logs kiosk session exits
- Restarts Firefox automatically if it crashes to keep kiosks online

### Auto-Login Configuration
- Systemd service override for getty
- Automatic login as 'kiosk' user
- No password prompt

## Deployment Strategy

### Automated Deployment
- Single deployment script (`deploy-kiosk.sh`)
- Copies all configuration files
- Sets appropriate permissions
- Configures system services
- Applies security hardening

### Customization Points
- URLs for kiosk application and license renewal
- License file URL
- Custom splash screen image
- Touch device specific configurations

## Security Considerations

### System Hardening
- Firewall limiting outbound connections
- Document additional outbound requirements (NTP, remote support tools, proxies) before enforcing strict firewall rules
- Disabled unnecessary services (bluetooth, cups, etc.)
- Automatic security updates
- Restricted user permissions

### License Security
- Online validation prevents unauthorized use
- Graceful handling of network issues
- System shutdown on license failure

## Testing and Validation

### Test Checklist
- [ ] System boots without errors
- [ ] Auto-login works correctly
- [ ] Custom splash screen displays
- [ ] License validation functions
- [ ] Browser starts in kiosk mode
- [ ] Touch screen responds properly
- [ ] On-screen keyboard appears
- [ ] System reboots correctly

### Troubleshooting Areas
- Auto-login configuration
- Touch device detection
- License URL accessibility
- X server startup
- Network connectivity

## Files Created for Implementation

### Documentation
- `ALPHA_KIOSK_IMPLEMENTATION.md` - Complete implementation guide
- `README.md` - Quick start guide
- This development brief

### Configuration Files
- `autologin.conf` - Systemd auto-login override
- `alpha-kiosk.plymouth` - Plymouth theme configuration
- `alpha-kiosk.script` - Splash screen script

### Scripts
- `deploy-kiosk.sh` - Automated deployment
- `license-check.sh` - License validation
- `touch-config.sh` - Touch configuration
- `.bash_profile` - Idempotent startx trigger for tty1 auto-login
- `.xinitrc` - Kiosk session management

## Next Steps for Implementation

1. **Customize URLs** in configuration files
2. **Prepare splash screen** (1920x1080 PNG)
3. **Test license file** accessibility
4. **Deploy to test hardware**
5. **Validate touch functionality**
6. **Perform security testing**
7. **Document any hardware-specific adjustments**

## Hardware Compatibility Notes

### Chromeboxes (mrchromebox)
- Standard Ubuntu drivers should work well
- Touch screen support via standard Linux drivers
- Good hardware compatibility expected

### All-in-One PCs
- May require specific touch driver identification
- Hardware-specific configurations may be needed
- Testing required for each model

## Maintenance Considerations

### Monitoring
- License validation logs
- Touch configuration logs
- System performance metrics
- Security update status

### Updates
- Regular system updates
- License file management
- Configuration backup
- Hardware compatibility testing

---

## Context for AI Handoff

This project involves creating a specialized Linux kiosk distribution with custom branding, licensing, and touch optimization. The implementation uses Ubuntu Server 22.04 LTS as a base, removes the desktop environment entirely, and implements a kiosk-only mode with auto-login and browser launch.

Key technical challenges addressed:
- Touch screen optimization and driver configuration
- On-screen keyboard integration
- License validation system with online checking
- Custom boot splash screen
- System hardening for public kiosk use

The solution is designed for deployment on repurposed hardware (Chromeboxes and All-in-One PCs) and includes comprehensive automation for deployment and maintenance.

All configuration files, scripts, and documentation have been created and are ready for implementation and testing.
