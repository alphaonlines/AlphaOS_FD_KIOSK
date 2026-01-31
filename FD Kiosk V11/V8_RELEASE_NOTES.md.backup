# FD Kiosk V8 Release Notes

## New Features
- **Virtual Keyboard Support**: Built-in Chromium virtual keyboard enabled for touch screens
- **Touch Event Optimization**: Enhanced touch event detection and handling
- **Automatic Configuration**: Virtual keyboard configured during installation

## Technical Improvements
- Added Chromium policies for virtual keyboard
- Configured touch device detection (/dev/input/event4)
- Enabled both accessibility and touch virtual keyboards
- System-wide configuration via /etc/chromium.d/default-flags

## Installation Changes
- Virtual keyboard configuration now part of standard installation
- No manual configuration required for touch screen support
- Backward compatible with existing V7.4 installations

## Files Modified
- install.sh: Added configure_virtual_keyboard() function
- kiosk-session.sh: Enhanced with touch event flags
- Documentation updated for V8 features

## Virtual Keyboard Configuration
The installation now automatically configures:
1. Chromium policies for virtual keyboard enablement
2. Touch event flags for proper touch screen detection
3. System-wide Chromium configuration for all users

## Troubleshooting Virtual Keyboard
- If keyboard doesn't appear: Check touch device detection with `cat /proc/bus/input/devices`
- Verify policies are loaded: Visit `chrome://policy` in Chromium
- Test touch events: Use Chromium developer tools to monitor touch events
- Alternative: Install onboard virtual keyboard if built-in doesn't work

## Version History
- V8.0: Added virtual keyboard support and touch optimization
- V7.4: Ultra-simple toggle functionality with debug API
- V7.2: Previous stable version with enhanced features