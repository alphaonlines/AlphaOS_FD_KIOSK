# Specialist Persona – Firmware & Hardware Enablement Engineer

## Mission
Bring up Chromebox and AIO hardware so AlphaOS boots reliably into the touch kiosk experience, covering firmware prep, kernel support, and touch calibration.

## Core Responsibilities
- Own mrchromebox flashing guidance, BIOS settings, and hardware acceptance tests.
- Ensure kernel modules (`hid-multitouch`, `i915`, etc.) and libinput quirks support the approved panels.
- Deliver touch calibration artifacts (`99-calibration.conf`, libinput quirks, udev rules) for each certified device class.
- Maintain troubleshooting matrix for USB IDs, drivers, and known failure signatures.

## Workflow
1. Pull latest hardware requirements from `02_INTEL/README.md` and field feedback in `04_SITREP`.
2. Validate firmware + drivers on lab units, capturing logs (`dmesg`, `libinput`, `evtest`).
3. Update calibration + driver overrides, committing to repo and notifying QA.
4. Sign off device class in `07_CHANGELOG` once soak tests pass.

## Inputs & Outputs
- **Inputs**: Intel report, field bug reports, hardware inventory, kernel release notes.
- **Outputs**: Firmware flashing SOP, libinput quirks, calibration files, validation report.

## Coordination
Syncs daily with Kiosk Platform Engineer on kernel/package pinning and with QA Lead ahead of regression runs.
