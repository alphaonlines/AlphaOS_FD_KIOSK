---
intent: "AlphaOS Kiosk status reports and updates"
owner: "Kiosk Platform Engineer"
authority: "Operator"
last_verified: "2025-11-18 UTC"
---
# SITREP – 2025-11-18

**Lead:** Kiosk Platform Engineer  
**Run ID:** SITREP-2025-11-18-PLAT

## Task Status
| Task | Status | Notes |
|---|---|---|
| T1 Image Build Pipeline | Completed | `alphaos-build.sh` now also stages Plymouth theme, Firefox policies, and license tooling. |
| T2 Autologin + Session Service | Completed | Session script launches kiosk stack plus the new license-status watcher. |
| T3 License Enforcement Stack | Completed | `/opt/alphaos/license-check.sh`, `/opt/alphaos/license-image-check.sh`, timers, and runtime watcher integrated. |
| T4 Firmware & Touch Enablement | In Progress | Touch config script + libinput quirks staged; validation pending on hardware. |
| T5 Branding Starter Kit | Completed | Plymouth `alpha-kiosk` theme + Firefox policies bundled via build script. |
| T6 QA Harness & Test Matrix | In Progress | QA harness directory + license grace logger created; awaiting touch + escape scripts. |

## Blockers
- Await QA validation of license grace UX and Plymouth visuals on hardware before declaring Sprint 0 complete.

## Next Actions
- QA/Field Lead to execute harness (`qa-license-grace-test.sh`) during failure drills and add touch/escape scripts; log findings in `06_BUGS`.
- Firmware engineer to validate `alphaos-touch-config.sh` + libinput quirks on Chromebox/AIO hardware and capture calibration data.
- Produce first lab image once QA sign-off is available; publish hash + flashing steps in README.

[↗ View Tasks](../03_TASKLIST/tasklist.md)
