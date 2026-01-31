# FD Kiosk V9 Release Notes

## New Features
- **xvkbd External Keyboard Integration**: Added external xvkbd keyboard with 9x15bold font
- **Font Visibility Fix**: Resolved invisible letters issue with optimized bitmap fonts
- **3X Keyboard Scaling**: Large 1200x600 keyboard geometry for kiosk displays
- **Always-On-Top Keyboard**: Keyboard stays above all windows for easy access
- **Keyboard Toggle Button**: ⌨ button at top-right for easy keyboard control
- **Automatic Font Configuration**: .Xresources file created and loaded during installation

## Technical Improvements
- Added xvkbd, xfonts-75dpi, xfonts-100dpi, and wmctrl packages to installation
- Integrated keyboard management functions in kiosk-ui.py
- Added keyboard process cleanup on application exit
- Enhanced .Xresources configuration for optimal large keyboard display
- Improved key sizing and spacing for 3X scaling (90x90 pixels vs 30x30 default)
- Better contrast and visibility settings for kiosk environment

## Installation Changes
- xvkbd keyboard configuration now part of standard installation
- Font packages automatically installed for bitmap font support
- .Xresources template created and loaded for user
- No manual configuration required for external keyboard
- Backward compatible with existing V8 installations

## Button Layout Updates
```
Top-left     +10+10      [← Back]
Top-right    {width-90}+10   [⌨ Keyboard]
Bottom-left  +10+{height-60}  [Furniture Distributors / AlphaPulse]
```

## xvkbd Keyboard Configuration
The installation now automatically configures:
1. **Font**: 9x15bold bitmap font for excellent visibility
2. **Geometry**: 1200x600+360+460 (3X scaling, centered)
3. **Key Sizes**: 90x90 pixels (3X default size)
4. **Special Keys**: Enhanced space bar (240px) and modifier keys
5. **Spacing**: Improved vertical/horizontal spacing for large display
6. **Contrast**: Better colors and shadows for key definition
7. **Always-On-Top**: Keyboard stays above browser window

## Files Modified
- install.sh: Added xvkbd packages and configure_xvkbd_keyboard() function
- kiosk-ui.py: Added keyboard management functions and toggle button
- .Xresources: Created font and geometry configuration template (new)
- README.md: Updated with xvkbd keyboard documentation
- V9_RELEASE_NOTES.md: Created comprehensive release notes (new)

## Troubleshooting xvkbd Keyboard
- If keyboard doesn't appear: Check xvkbd installation with `which xvkbd`
- If letters are not visible: Verify font with `xlsfonts | grep 9x15bold`
- If keyboard not on top: Check wmctrl with `which wmctrl`
- If geometry wrong: Check .Xresources with `xrdb -query | grep xvkbd`
- Test keyboard manually: `xvkbd -geometry 1200x600+360+460 -xrm "xvkbd*Font: 9x15bold"`

## Font Package Requirements
- xfonts-75dpi: Essential for bitmap font support
- xfonts-100dpi: Additional font resolution options
- xvkbd: External virtual keyboard application
- wmctrl: Window management for always-on-top functionality

## Version History
- V9.0: Added xvkbd external keyboard with font visibility fixes
- V8.0: Added Chromium virtual keyboard support and touch optimization
- V7.4: Ultra-simple toggle functionality with debug API
- V7.2: Previous stable version with enhanced features

## Benefits Achieved
- **Visible Letters**: Bold, clear characters on all keyboard keys
- **Large Display**: Optimized for 3X scaling (1200x600)
- **Reliable Operation**: Robust bitmap font that works consistently
- **User Experience**: Much more usable keyboard interface
- **Zero Configuration**: Everything works out-of-the-box after installation
- **Integration**: Seamlessly integrated with existing V8 features