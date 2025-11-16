# AlphaOS Touch Kiosk – Changelog

# AlphaOS Touch Kiosk – Changelog

## v0.3.0 (2025-11-18)
- **Lead:** Security & Branding Team
- **Scope:** Sprint 0 Tasks 3 & 5 integration.
- **Details:**
    - Added hardened license enforcement stack (`license-check.sh`, biweekly image probe, timers, session watcher).
    - Packaged Plymouth `alpha-kiosk` theme, Firefox ESR policies, and build-script automation to copy them into the rootfs.
    - Updated SITREP and README to reflect new operational components and objectives.

## v0.2.0 (2025-11-17)
- **Lead:** Kiosk Platform Engineer
- **Scope:** Sprint 0 Tasks 1–2 groundwork.
- **Details:**
    - Added `alphaos-build.sh` to automate jammy rootfs creation, kiosk package install, and license URL embedding.
    - Authored `alphaos-session.sh` plus `alphaos-session.service` and tty1 autologin override for matchbox/onboard/Firefox kiosk session.
    - Documented platform deliverables inside `01_README/README.md` and logged status in SITREP.

## v0.1.0 (2025-11-16)
- Initial corp template import and mission scaffolding from AlphaOS brief.
