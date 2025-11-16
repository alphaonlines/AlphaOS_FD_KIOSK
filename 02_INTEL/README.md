# AlphaOS Touch Kiosk Intel Report

## Executive Summary
- Base the image on Ubuntu Server 22.04 LTS minimal, layer only the packages required for graphics (`xorg`, `xserver-xorg-input-libinput`, minimal window manager), Firefox, screen keyboard (`onboard`), and supporting daemons (`network-manager`, `openssh-server` for remote ops). Boot straight into a kiosk user session managed by systemd, not a full desktop.
- Run Firefox in `--kiosk --private-window` mode via a dedicated `kiosk.service` that starts Xorg and a lightweight window manager (Matchbox or Openbox) for predictable focus and no chrome. Launch the AlphaOS portal URL plus the license enforcement watchdog before the browser becomes interactive.
- Implement license validation as a systemd timer calling a hardened script that reads the URL stored at `00_PLACE START FILE HERE/New Text Document.txt` (`https://cdn.shopify.com/s/files/1/0790/0525/3951/files/FD_server_link.jpg?v=1762569746`). Cache last-known-good responses, log to journal, alert the UI on repeated failures, and block the kiosk session if validation fails beyond the grace window.
- Touch support hinges on firmware enablement (mrchromebox UEFI, kernel modules `hid-multitouch`, `usbhid`, `i915`) plus libinput tweaks and calibration layers for typical AIO panels. Pair this with `onboard` launched as an always-on DBus service and `gsettings` profiles tuned for large hit targets.
- Branding spans boot (Plymouth theme+GRUB splash), login (custom getty + ASCII logotype), and runtime (Firefox policies, CSS for the kiosk site, unclutter + wallpaper). Keep everything signed and versioned so kiosk rebuilds remain reproducible.
- Major risks: hardware variance in touch panels, kiosk escape via key combos, Firefox rendering regressions after updates, and network loss affecting license checks. Mitigations include pre-validating panels, intercepting VT switches, pinning Firefox ESR, and grace periods / watchdog reporting.

---

## Key Question 1 – Booting directly into a touch-friendly browser session
- **Packages & components**: `xorg`, `xserver-xorg-video-intel` (Chromebox), `xserver-xorg-video-vesa` (fallback AIO), `xserver-xorg-input-libinput`, `mesa-utils`, `matchbox-window-manager` (no taskbar), `firefox`, `dbus-x11`, `fonts-noto`, `unclutter`, `onboard`, `network-manager`, `openssh-server`, `policykit-1`, `systemd-timesyncd`, `rsyslog` (or journald only), `ufw`.
- **Systemd-controlled autologin**: override `getty@tty1.service` to autologin user `kiosk`; `.bash_profile` calls `/usr/bin/startx /usr/local/bin/alphaos-session.sh -- :0 vt1 -nocursor`.
- **Session script (`alphaos-session.sh`)**: start matchbox/openbox, set environment (`GTK_IM_MODULE=ibus`, `XDG_RUNTIME_DIR=/run/user/1001`), launch `onboard --xid --not-show-in systray`, then `firefox --kiosk --private-window $PORTAL_URL`.
- **Security hardening**: disable TTY switching (`sudo systemctl mask ctrl-alt-del.target`, `install -m 644 /etc/systemd/system/getty@tty1.service.d/noclr.conf`), remap power key, enforce `ufw default deny incoming`, run Firefox with `MOZ_ENABLE_WAYLAND=0` to stay on Xorg for kiosk tooling unless Wayland + wlr kiosk is proven stable.
- **Updates**: stage via `unattended-upgrades` but hold `firefox` at ESR version tested for kiosk. Snapshot system (e.g., `snapper`) before applying updates for quick rollback.

## Key Question 2 – License validation tied to provided URL
- **Source of truth**: read URL from `00_PLACE START FILE HERE/New Text Document.txt` during image build and bake into `/etc/alphaos/license-url` so kiosks update if the drop-files changes.
- **Service design**:
  - `/opt/alphaos/license-check.sh` runs `curl --fail --tlsv1.2 --proto =https --connect-timeout 5 "$LICENSE_URL"` and validates signature/hash of payload.
  - Store success metadata under `/var/lib/alphaos/license-state.json` (timestamp, hash, grace counter). Never log raw tokens; only statuses.
  - `alphaos-license-check.service` (oneshot) + `alphaos-license-check.timer` (OnBootSec=30s, OnUnitActiveSec=15m). Enable `StartLimitIntervalSec=0` so repeated failures don’t deadlock.
  - On failure, raise `systemd-notify --status`, send D-Bus signal to browser overlay so kiosk displays “Activation lost” message but continues for the grace window (e.g., 4 hours) before forcing logout.
  - Send logs to journal (`journalctl -u alphaos-license-check`), optionally forward via `rsyslog` TCP to central monitoring.
- **Hardening**: dedicate `alphaos-licd` user, confine script with `SystemCallFilter`, `PrivateTmp`, `ReadOnlyPaths=/`, `ReadWritePaths=/var/lib/alphaos`. Optionally verify pinned certificate fingerprint via `openssl s_client` or `--pinnedpubkey`.

## Key Question 3 – Reliable touch + on-screen keyboard
- **Firmware + drivers**: On Chromeboxes, flash mrchromebox UEFI (coreboot + Tianocore) to unlock legacy boot; confirm BIOS enables USB boot and disables Verified Boot. Ensure kernel has `hid-multitouch`, `usbhid`, `i2c-hid`, `i915`, `intel-lpss`. Keep `linux-oem-22.04` kernel handy for newer touch ICs.
- **libinput tuning**: Use `/etc/libinput/local-overrides.quirks` to set `MatchName` and `AttrTouchSizeRange` for panels that misreport contact sizes. `libinput list-devices` + `libinput debug-events` to capture gestures; for axis inversion write `/etc/X11/xorg.conf.d/99-calibration.conf` with `Option "Calibration"` coordinates (from `xinput_calibrator`).
- **AIO diversity**: Pre-bundle vendor blobs for EloTouch, eGalax, Goodix. Provide `udev` rules mapping USB IDs to correct kernel modules. Validate with `evtest`.
- **On-screen keyboard**: install `onboard`, set `/usr/lib/systemd/user/onboard.service` to autostart, and run `gsettings set org.onboard layout 'Large'`. Configure `onboard-settings -l` to use transparent dock anchored bottom. Provide fallback `matchbox-keyboard` for low-resource scenarios.
- **Touch UX**: prefer `Firefox + WindowTouchMode=1` (in `about:config`) so scrollbars widen and double-tap context menu disabled. Force 125% scaling via `gsettings set org.gnome.desktop.interface text-scaling-factor 1.25`.

## Key Question 4 – Branding steps
- **Boot chain**: customize Plymouth theme via `/usr/share/plymouth/themes/alphaos/` (symlink to assets). Run `sudo plymouth-set-default-theme alphaos` and `sudo update-initramfs -u`. Align GRUB splash by editing `/etc/default/grub` (`GRUB_BACKGROUND=/boot/grub/themes/alphaos/bg.png`) then `update-grub`.
- **Login & session**: replace default getty banner with `/etc/issue` ASCII art. Use `systemd-ask-password-wall` for emergency prompts featuring brand colors. Provide custom cursor + wallpaper under `/usr/share/images/alphaos/`.
- **Browser chrome**: manage Firefox via `/usr/lib/firefox/distribution/policies.json` to disable context menus, print, about:config, updates, and enforce the kiosk home URL. Inject CSS via extension or `userChrome.css` for brand colors. Consider `ssb` via `webapp-manager` if isolating.
- **Content protection**: `unclutter -idle 0.5` to hide cursor, `xset -dpms` to stop blanking, but schedule `xset dpms force suspend` overnight via cron for panel longevity. Mirror brand fonts via `fonts-alphaos`.

## Key Question 5 – Risks and mitigations
- **Touch variance**: Non-standard HID descriptors or ghost touches → maintain per-panel config repo, run hardware acceptance tests before imaging, keep calibration UI accessible via hidden hotkey.
- **Kiosk escape vectors**: Ctrl+Alt+Fx, Alt+Tab, Firefox dialogs → mask VT switching, disable `Alt+SysRq`, use `polkit` rules to deny reboots, set Firefox policies to suppress modal dialogs and PDF downloads.
- **Network outages/license**: repeated failures lock users out → implement exponential backoff + cached tickets, add offline grace tokens (signed JSON) distributed at provisioning.
- **Firefox updates**: Upstream UI tweaks can break kiosk CSS → pin ESR, stage updates in CI with automated Selenium/touch tests.
- **Thermal/perf**: Chromebox fan curves may not ramp under kiosk load → ship `lm-sensors` monitoring + `fancontrol` config; throttle via `intel_pstate=passive` if kiosks operate in warm venues.

## Specialist Personas (roles & focus)
1. **Firmware & Hardware Enablement Engineer** – owns mrchromebox flashing, driver bring-up, libinput quirks, and hardware acceptance.
2. **Kiosk Platform Engineer** – builds the Ubuntu image, systemd services, Firefox kiosk session, and lockdown policies.
3. **Security & Licensing Engineer** – designs license verification service, cert pinning, secure logging, and watchdog integrations.
4. **Brand & UX Systems Designer** – produces Plymouth/GRUB themes, Firefox chrome, touchscreen UX polish, and accessibility (larger touch targets, on-screen keyboard layouts).
5. **QA & Field Reliability Lead** – automates regression runs on Chromebox + AIO hardware, exercises touch/scroll cases, runs soak tests, and coordinates rollback procedures.

## References
- Ubuntu Touchscreen docs – https://wiki.ubuntu.com/Touchscreen
- Libinput reference – https://wayland.freedesktop.org/libinput/doc/latest/quirks.html
- Firefox kiosk mode guide – https://support.mozilla.org/en-US/kb/run-firefox-kiosk-mode
- Firefox enterprise policies – https://firefox-source-docs.mozilla.org/enterprise/policies/index.html
- Plymouth theming – https://wiki.ubuntu.com/Plymouth
- systemd timers – https://www.freedesktop.org/software/systemd/man/systemd.timer.html
