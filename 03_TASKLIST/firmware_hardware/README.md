# Firmware & Touch Enablement Pack

## Hardware Targets
- **Chromebox (mrchromebox-flashed)** – Requires UEFI firmware update, USB boot enablement, kernel modules `hid-multitouch`, `i915`.
- **All-in-One Touch PCs** – Varies (Elo, eGalax, Goodix). Ship libinput quirks + calibration snippets.

## Deliverables
1. `touch-config.sh` – XInput helper enabling natural scrolling, tap-to-click, and consistent scroll method for detected touchpads/panels. Run once per session.
2. `libinput/local-overrides.quirks` – Example quirks for USB IDs requiring custom touch size or axis inversion.
3. `xorg/99-alphaos-touch.conf` – Calibration skeleton honoring per-hardware environment variables.
4. Firmware checklist (below) to prep Chromebox with mrchromebox util.

## Firmware Checklist (Chromebox)
1. Boot to stock ChromeOS, enable developer mode.
2. Run mrchromebox firmware utility: `cd; curl -LO mrchromebox.tech/firmware-util.sh && sudo bash firmware-util.sh`.
3. Flash UEFI firmware, enable USB boot + disable write protect.
4. After flashing, set BIOS defaults (UEFI first, disable secure boot if necessary).

## Touch Workflow
1. During image build, install `touch-config.sh` to `/usr/local/bin/alphaos-touch-config.sh` and invoke it from `alphaos-session.sh` before launching Firefox.
2. Drop quirks into `/etc/libinput/local-overrides.quirks`; include entries for common panels.
3. Provide `xorg/99-alphaos-touch.conf` to `/usr/share/X11/xorg.conf.d/` for fallback calibration (values can be overridden via `/etc/alphaos/touch-calibration.conf`).

## Logs & Acceptance
- `touch-config.sh` logs to `/var/log/touch-config.log`.
- QA captures `libinput debug-events` traces while running TCH test cases (see `03_TASKLIST/qa_field/README.md`).
