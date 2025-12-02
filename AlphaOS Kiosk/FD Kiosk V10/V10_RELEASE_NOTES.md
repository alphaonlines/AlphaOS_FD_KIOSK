# FD Kiosk V10 Release Notes

## Key Fixes and Improvements
- **AlphaPulse URL Correction**: Fixed secondary URL from `https://alphaonlines.org/pages/aj-test` to `https://AlphaonlineS.github.io/AlphaPulse`
- **xvkbd Keyboard Integration**: Fully functional external virtual keyboard with 9x15bold font
- **Package Dependencies**: Ensured xvkbd, xfonts-75dpi, xfonts-100dpi, and wmctrl are properly installed
- **Zero Configuration**: Keyboard works out-of-the-box without manual setup

## Technical Updates
- **Version Bump**: Updated all version references from 9.0 to 10.0
- **Install Script**: Updated default SECONDARY_URL to correct AlphaPulse destination
- **Documentation**: Updated README.md with correct URLs and installation path
- **Code Comments**: Updated kiosk-ui.py header to reflect V10 version

## Installation Improvements
- **Correct Default URLs**: Primary URL points to furnituredistributors.net, Secondary URL points to AlphaonlineS.github.io/AlphaPulse
- **Automatic xvkbd Setup**: Virtual keyboard packages installed and configured during installation
- **Font Configuration**: .Xresources automatically created with optimal 9x15bold font settings
- **Always-On-Top**: Keyboard configured to stay above browser window

## User Experience Enhancements
- **Working Keyboard Button**: ⌨ button now properly toggles virtual keyboard visibility
- **Correct Toggle Functionality**: Toggle button switches between correct URLs
- **Large Display**: 1200x600 keyboard geometry optimized for kiosk displays
- **Clear Visibility**: Bold bitmap fonts ensure all characters are clearly visible

## Files Modified
- **install.sh**: Updated SECONDARY_URL and version number
- **README.md**: Updated version, URLs, and installation path
- **kiosk-ui.py**: Updated version comment
- **V10_RELEASE_NOTES.md**: Created comprehensive release notes (new)

## Troubleshooting Improvements
- **Keyboard Not Working**: xvkbd package now automatically installed
- **Wrong URL**: AlphaPulse URL corrected in default configuration
- **Font Issues**: Bold bitmap fonts properly configured during installation
- **Window Management**: wmctrl included for always-on-top functionality

## Verification Steps
After installation, verify:
1. **Keyboard Button**: Click ⌨ button to show/hide virtual keyboard
2. **Toggle Button**: Should switch between Furniture Distributors and AlphaPulse
3. **URL Correctness**: AlphaPulse should navigate to `https://AlphaonlineS.github.io/AlphaPulse`
4. **Font Visibility**: All keyboard characters should be clearly visible

## Package Dependencies Included
- `xvkbd`: External virtual keyboard application
- `xfonts-75dpi`: Essential bitmap font support
- `xfonts-100dpi`: Additional font resolution options  
- `wmctrl`: Window management for always-on-top functionality
- `python3-tk`: Tkinter support for UI
- `python3-requests`: HTTP requests for toggle functionality

## Version History
- **V10.0**: URL correction and xvkbd keyboard integration fixes
- **V9.0**: Added xvkbd external keyboard with font visibility fixes
- **V8.0**: Added Chromium virtual keyboard support and touch optimization
- **V7.4**: Ultra-simple toggle functionality with debug API

## Benefits Achieved
- **Correct Navigation**: Toggle button now goes to the right AlphaPulse URL
- **Working Keyboard**: Virtual keyboard functions properly without manual setup
- **Better UX**: Clear, visible keyboard with large display
- **Zero Maintenance**: Everything works out-of-the-box after installation
- **Future-Proof**: Clean V10 baseline for future developments

## Installation Commands
```bash
cd "/home/fduser/Desktop/FD Kiosk V10"
chmod +x *.sh kioskctl
./install.sh
```

## Management Commands
```bash
kioskctl start|stop|restart|status|logs|doctor
```