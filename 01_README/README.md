# AlphaOS Touch Kiosk Overview

## Mission
Deliver a locked-down Ubuntu 22.04 minimal image that boots directly into a touch-first Firefox kiosk, validates licenses via the Shopify URL, and ships branded UX across Chromebox + AIO hardware.

## Workstreams & Owners
1. **Platform** *(Kiosk Platform Engineer)* – Automate the build pipeline, kiosk session services, and lockdown policies.
2. **Firmware/Hardware** *(Firmware & Hardware Engineer)* – Flash guidance, kernel enablement, touch calibration, hardware acceptance.
3. **Security/Licensing** *(Security & Licensing Engineer)* – License check daemon, TLS/pinning, logging, and hardening controls.
4. **Brand & UX** *(Brand & UX Designer)* – Plymouth/GRUB themes, Firefox policies, on-screen keyboard ergonomics, accessibility.
5. **QA & Reliability** *(QA & Field Lead)* – Regression suites, soak tests, readiness reports, bug tracking.

## Near-Term Objectives
- Produce scripted ISO/disk image with kiosk autologin + matchbox session.
- Implement license validation (service+timer) with caching/grace logic, `/run/alphaos/license-status` reporting, and the biweekly Shopify asset probe.
- Validate touch firmware + calibration for launch hardware, documenting variance.
- Integrate branding assets end-to-end (Plymouth `alpha-kiosk` theme, Firefox policies) and pin Firefox ESR configuration.
- Stand up QA harness covering touch, kiosk escape attempts, license failure handling, and branding fidelity.

## Milestones
- **Sprint 0 (Foundation)**: Complete tasks 1–6 in `03_TASKLIST/tasklist.md`; deliver first lab-ready image.
- **Sprint 1 (Integration)**: Execute tasks 7–10; produce release candidate, QA sign-off, deployment SOP.

## Activation Notes
- Specialists operate only from `03_TASKLIST/tasklist.md`; updates flow through `04_SITREP` and `07_CHANGELOG`.
- License URL source of truth remains `00_PLACE START FILE HERE/New Text Document.txt`; Platform Engineer must bake it into `/etc/alphaos/license-url`.
- Security stack now includes `/opt/alphaos/license-check.sh`, `/opt/alphaos/license-image-check.sh`, `alphaos-license-*.service/timer`, and `/usr/local/bin/alphaos-license-watch.sh` (session warning helper).
- Plymouth + Firefox payloads sourced from `03_TASKLIST/brand_ux/`; `alphaos-build.sh` copies them into the rootfs and runs `plymouth-set-default-theme alpha-kiosk`.
- Firmware pack lives in `03_TASKLIST/firmware_hardware/` (touch config script, libinput quirks, calibration stub) and gets installed via `alphaos-build.sh`.
- QA harness lives in `03_TASKLIST/qa_field/` (matrix + `qa-license-grace-test.sh`) and must be run on Chromebox + AIO hardware before sign-off.
- All research updates appended to `02_INTEL/README.md`; bugs filed in `06_BUGS`.

## Platform Engineer Deliverables (Sprint 0)
- `03_TASKLIST/kiosk_platform/alphaos-build.sh` – run as root to debootstrap Ubuntu 22.04, install kiosk packages, embed the Shopify license URL, and copy local configs into the build artifact (`sudo ./alphaos-build.sh build-output`).
- `03_TASKLIST/kiosk_platform/alphaos-session.sh` – kiosk session launcher referenced by `alphaos-session.service`, starting Matchbox, Onboard, and Firefox in kiosk mode with DPMS disabled.
- `03_TASKLIST/kiosk_platform/systemd/alphaos-session.service` – user-level service bound to `graphical.target`; enable after copying into `/etc/systemd/system`.
- `03_TASKLIST/kiosk_platform/systemd/getty@tty1.service.d/override.conf` – autologin override for tty1 to ensure `kiosk` user launches the session script automatically.
