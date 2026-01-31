# Agent notes (Version 11.0)

## Assistant Personality

- **Role**: Helpful coding assistant focused on development tasks and system configuration
- **Traits**: Concise, direct, security-conscious, follows existing code conventions
- **Approach**: 
  - Read existing code patterns before making changes
  - Use available libraries and utilities already present in the codebase
  - Prioritize security best practices (never expose secrets/keys)
  - Run lint/typecheck commands when available to verify code quality
  - Provide minimal but complete responses focused on the specific task

- Defaults: `BROWSER=chromium`, `PRIMARY_URL=https://furnituredistributors.net`, `SECONDARY_URL=https://AlphaonlineS.github.io/AlphaPulse`, `DEBUG_PORT=9222`, `REBOOT_TIME=03:30`, `PROFILE_DIR=~/.local/share/kiosk-${BROWSER}`.
- Services: `kiosk-session.service` (browser), `kiosk-ui.service` (toggle/back/scroll overlays), `kiosk-reboot.service` + `kiosk-reboot.timer`, bundled under `kiosk.target`. Autostart entry runs `kioskctl start`.
- UI state lives at `/tmp/kiosk-current-url.txt`; toggle uses Chromium remote-debug (`http://127.0.0.1:$DEBUG_PORT/json/new?URL`) and updates the state file.
- Browser swap path: `kiosk-ui.py` uses the debug API directly; no xdotool tab navigation for toggle.
- Reboot prompt uses `zenity` and `systemctl reboot` on confirm; if zenity is missing it reboots immediately.
- Dependencies installed via apt in `install.sh`: chromium, chromium-sandbox, firefox-esr, xdotool, wmctrl, unclutter, zenity, jq, curl, dbus-x11, x11-xserver-utils, python3-gi, gir1.2-gtk-3.0, python3-requests, at-spi2-core, xvkbd, xfonts-75dpi, xfonts-100dpi.
- To reconfigure: set env vars (above) and re-run `install.sh`; systemd units are regenerated with the new values. V11 sets `GTK_MODULES=atk-bridge` and `NO_AT_BRIDGE=0` in units.
- Diagnostics: `kioskctl doctor` prints key envs and checks for `xdotool/unclutter/zenity`; `kioskctl logs` tails session/ui/timer units.
- Codex CLI Installation (OpenAI's coding assistant):
  - **Via npm (recommended)**: `npm install -g @openai/codex`
  - **Via Homebrew (macOS/Linux)**: `brew install codex`
  - **Manual download**: Visit https://github.com/openai/codex/releases
  - **Setup**: `export OPENAI_API_KEY=Your-API-Key`
  - **Verify**: `codex --version`
  - **Usage**: `codex` to start interactive mode or `codex "your prompt"` for direct commands

## Change Tracking
- **2025-11-29**: Created Version-7.2 by copying Version-7.1 to fix autologin issue.
- **2025-11-29**: Added configure_autologin() function to install.sh to configure LightDM autologin for KIOSK_USER.
- **2025-11-29**: Updated main() function to call configure_autologin() after install_branding().
- **2025-11-29**: Fixed configure_autologin() function placement in install.sh (moved before main() function).
- **2025-11-29**: Successfully completed installation with all packages, scripts, systemd units, and LightDM autologin configured for fduser.
- **2025-11-29**: Installation notes: XFCE background setting failed (property missing), but core kiosk functionality installed. Ready for reboot testing.
- **2026-01-31**: Created Version 11.0 from V10 to harden Debian XFCE installs.
- **2026-01-31**: Installer now attempts `dpkg --configure -a` before apt install to recover from interrupted dpkg state.
- **2026-01-31**: XFCE wallpaper setup now creates missing xfconf properties with `-n -t` flags.
- **2026-01-31**: systemd user unit enable uses explicit `XDG_RUNTIME_DIR` and `DBUS_SESSION_BUS_ADDRESS`.
- **2026-01-31**: Installer auto-writes Debian 13 sources when none are present (`AUTO_APT_SOURCES=1` default).
