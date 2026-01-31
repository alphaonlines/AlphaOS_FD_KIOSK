# FD Kiosk Version 11.0

## Overview
Version 11.0 of the FD Kiosk system with ultra-simple toggle functionality using Chromium debug API, xvkbd auto-show keyboard support (via AT-SPI focus events), and integrated xvkbd external keyboard with visible bold fonts.

## Kiosk Shell (Remote Management Blueprint)
The `kiosk shell/` folder contains the MVP blueprint for centralized kiosk management (broker + controller + dashboard + kiosk agent). This is intended for a future VPS deployment but can be run locally on the setup PC for smoke testing.

Quick layout:
- `kiosk shell/server/broker/`: Mosquitto mTLS config + ACLs.
- `kiosk shell/server/controller/`: Flask API to publish commands + store results.
- `kiosk shell/server/dashboard/`: Web UI that talks to controller API.
- `kiosk shell/agent/`: Kiosk agent with heartbeat + command queue.
- `kiosk shell/SCHEMA.md`: MQTT + API payload schema.
- `kiosk shell/INTEGRATION.md`: End-to-end runbook.
- `kiosk shell/PRODUCTION_CHECKLIST.md`: Production readiness checklist.

If you want a single consolidated agent brief, see:
- `kiosk shell/agents/AGENTS_ALL.md`

## Key Improvements
- **xvkbd External Keyboard**: Integrated external keyboard with 9x15bold font for excellent visibility
- **Font Visibility Fix**: Resolved invisible letters issue with optimized bitmap fonts
- **3X Keyboard Scaling**: Large 1200x600 keyboard geometry for kiosk displays
- **Always-On-Top**: Keyboard stays above all windows for easy access
- **Auto-Show Keyboard**: xvkbd auto-appears on focus using AT-SPI accessibility events
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

Bottom-left  +10+{height-60}  [Furniture Distributors / AlphaPulse]
```

## Installation (Kiosk App)
```bash
cd "/home/fduser/Desktop/FD Kiosk V11"
chmod +x *.sh kioskctl
./install.sh
```

## Kiosk Shell (Local Smoke Test)
If you want to validate the shell stack locally before production, see:
- `kiosk shell/INTEGRATION.md` for the runbook.
- `kiosk shell/PRODUCTION_CHECKLIST.md` for deployment steps.

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
- `kiosk-ui.py`: UI with toggle, back, and keyboard button
- `kiosk-session.sh`: Browser launcher script
- `install.sh`: Installation and configuration script with accessibility + xvkbd support
- `kioskctl`: Management utility
- `kiosk-reboot-if-idle.sh`: Nightly reboot script
- `.Xresources`: xvkbd font and geometry configuration

## Virtual Keyboard Support
- **Auto-Show**: On-screen keyboard appears automatically when inputs focus
- **xvkbd External Keyboard**: Large 1200x600 keyboard with 9x15bold font
- **Automatic Configuration**: Accessibility enabled during install

## Troubleshooting
- Toggle button not working? Check debug port: `curl http://127.0.0.1:9222/json/list`
- Browser crashed? Restart with: `systemctl --user restart kiosk-session.service`
- Button text wrong? Check state file: `cat /tmp/kiosk-current-url.txt`
- xvkbd keyboard not visible? Check font: `xlsfonts | grep 9x15bold`
- xvkbd letters missing? Check resources: `xrdb -query | grep xvkbd`
- Keyboard not appearing? Check it is running: `pgrep -x xvkbd`
- Auto-show not working? Verify accessibility: `gsettings get org.gnome.desktop.interface toolkit-accessibility`

## Technical Notes
- Uses Chromium Remote Debugging Protocol for reliable navigation
- Eliminates complex xdotool window detection and keystroke simulation
- Simple error handling with silent fail on debug API issues
- Maintains button state via local file for text updates
