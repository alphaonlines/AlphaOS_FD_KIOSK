# FD Kiosk Version 11.0 - Release Notes

## Fixes
- Installer now attempts to recover from interrupted dpkg state before apt install.
- XFCE wallpaper configuration now creates missing xfconf properties.
- systemd user units are enabled with explicit DBus/XDG runtime env so enabling works outside a user session.
- Installer warns when apt sources are missing and can auto-write Debian 13 sources when AUTO_APT_SOURCES=1.

## Notes
- V11 retains V10 features and the AT-SPI/xvkbd auto-show improvements.
- If dpkg was interrupted, you can still run: sudo dpkg --configure -a
