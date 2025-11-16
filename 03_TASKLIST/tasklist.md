# Task List – AlphaOS Touch Kiosk

## Sprint 0 – Foundation
1. **Image Build Pipeline** *(Kiosk Platform Engineer)* – Script Ubuntu 22.04 minimal provisioning (debootstrap/cloud-init), create kiosk user, install baseline packages (Xorg, matchbox, Firefox, onboard, NetworkManager, OpenSSH).
2. **Autologin + Session Service** *(Kiosk Platform Engineer)* – Implement systemd overrides for `getty@tty1`, write `alphaos-session.sh`, launch matchbox, onboard, and Firefox `--kiosk --private-window`.
3. **License Enforcement Stack** *(Security & Licensing Engineer)* – Build `/opt/alphaos/license-check.sh`, `alphaos-license-check.service` + `.timer`, caching/grace policy, and state reporting in `/run/alphaos/license-status` using URL in `00_PLACE START FILE HERE/New Text Document.txt`.
4. **Firmware & Touch Enablement Pack** *(Firmware & Hardware Engineer)* – Document mrchromebox flashing steps, validate kernel modules, deliver libinput quirks + calibration for Chromebox + target AIO.
5. **Branding Starter Kit** *(Brand & UX Designer)* – Produce Plymouth/GRUB themes, Firefox policies, and Onboard layout guidelines aligned with AlphaOS branding.
6. **QA Harness & Test Matrix** *(QA & Field Reliability Lead)* – Define regression suites (touch, kiosk escape, license failure), add harness scripts under `03_TASKLIST/qa_field/` (e.g., `qa-license-grace-test.sh`), set up logging templates, and prepare soak-test schedule.

## Sprint 1 – Integration
7. **Security Hardening Pass** *(Security & Licensing Engineer)* – Apply ufw defaults, polkit lockdown, disable VT switching, document Firefox ESR pinning.
8. **Touch UX Polish** *(Brand & UX Designer + Firmware Engineer)* – Tune scaling, gestures, Onboard behavior; verify across hardware list.
9. **Telemetry & Reporting Hooks** *(Security + QA)* – Configure journald/rsyslog forwarding for license and system health signals.
10. **Field Deployment SOP** *(Manager + QA)* – Write flashing, rollback, and support procedures referencing release artifacts.
