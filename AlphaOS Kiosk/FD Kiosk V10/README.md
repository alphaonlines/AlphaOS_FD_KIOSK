# FD Kiosk Version 10.0

## Overview
Version 10.0 of the FD Kiosk system with ultra-simple toggle functionality using Chromium debug API, built-in virtual keyboard support, and integrated xvkbd external keyboard with visible bold fonts.

## Key Improvements
- **xvkbd External Keyboard**: Integrated external keyboard with 9x15bold font for excellent visibility
- **Font Visibility Fix**: Resolved invisible letters issue with optimized bitmap fonts
- **3X Keyboard Scaling**: Large 1200x600 keyboard geometry for kiosk displays
- **Always-On-Top**: Keyboard stays above all windows for easy access
- **Keyboard Toggle Button**: ⌨ button at top-right for easy keyboard control
- **Virtual Keyboard Support**: Built-in Chromium virtual keyboard enabled for touch screens
- **Touch Event Optimization**: Enhanced touch event detection and handling
- **Automatic Configuration**: Both virtual keyboards configured during installation
- **Ultra-Simple Toggle**: 3-line function using debug API instead of complex window detection
- **Reliable Navigation**: Direct HTTP requests to Chromium debug port (9222)
- **No Crashes**: Removed tab management that caused browser instability
- **Minimal Dependencies**: Only requests + basic xdotool for back navigation
- **Screen Reader Fix**: Permanently disabled accessibility features that interfered with kiosk operation
- **Stable Performance**: Solid working version with all major issues resolved
- **Removed Scroll Buttons**: Native browser scrolling works well, eliminating need for custom scroll controls

## Button Layout
```
Top-left     +10+10      [← Back]

Top-right    {width-90}+10   [⌨ Keyboard]

Bottom-left  +10+{height-60}  [Furniture Distributors / AlphaPulse]
```

## Installation
```bash
cd "/home/fduser/Desktop/FD Kiosk V10"
chmod +x *.sh kioskctl
./install.sh
```

## Management
```bash
kioskctl start|stop|restart|status|logs|doctor
```

## How Toggle Works
1. **Button Click** → Calls ultra-simple toggle function
2. **Debug API** → Opens new tab with target URL via HTTP request
3. **State Update** → Updates button text and saves current URL
4. **No Tab Closing** → Leaves old tabs open (prevents crashes)

## Configuration
- Primary URL: https://furnituredistributors.net
- Secondary URL: https://AlphaonlineS.github.io/AlphaPulse
- Browser: Chromium (default)
- Debug Port: 9222

## Files
- `kiosk-ui.py`: UI with toggle, back, and keyboard buttons
- `kiosk-session.sh`: Browser launcher script
- `install.sh`: Installation and configuration script with xvkbd support
- `kioskctl`: Management utility
- `kiosk-reboot-if-idle.sh`: Nightly reboot script
- `.Xresources`: xvkbd font and geometry configuration

## Virtual Keyboard Support
- **xvkbd External Keyboard**: Large 1200x600 keyboard with 9x15bold font
- **Font Visibility**: Bold bitmap fonts ensure letters are clearly visible
- **Always-On-Top**: Keyboard stays above all windows for easy access
- **Keyboard Toggle**: Click ⌨ button to show/hide keyboard
- **Automatic Configuration**: Both virtual keyboards configured during installation
- **Touch Device Detection**: Automatically detects and configures touch screens
- **System-wide**: Works for all Chromium instances on the system
- **Touch Events**: Enhanced touch event handling for kiosk mode

## Troubleshooting
- Toggle button not working? Check debug port: `curl http://127.0.0.1:9222/json/list`
- Browser crashed? Restart with: `systemctl --user restart kiosk-session.service`
- Button text wrong? Check state file: `cat /tmp/kiosk-current-url.txt`
- xvkbd keyboard not visible? Check font: `xlsfonts | grep 9x15bold`
- xvkbd letters missing? Check resources: `xrdb -query | grep xvkbd`
- Virtual keyboard not appearing? Check policies: Visit `chrome://policy` in Chromium
- Touch events not working? Verify device: `cat /proc/bus/input/devices | grep -A5 -B5 "Touch"`

## Technical Notes
- Uses Chromium Remote Debugging Protocol for reliable navigation
- Eliminates complex xdotool window detection and keystroke simulation
- Simple error handling with silent fail on debug API issues
- Maintains button state via local file for text updates