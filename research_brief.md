# Research Brief: AlphaOS Touch Kiosk

## Objective
Provide the technical intelligence required to build a branded Ubuntu Server 22.04 LTS kiosk OS that auto-launches a hardened browser session with touch and on-screen keyboard support on Chromeboxes (mrchromebox) and All-in-One PCs. The deployment must include a license validation check that points to the URL stored in `00_PLACE START FILE HERE/New Text Document.txt`.

## Key Questions
1. What packages, services, and configurations are required to boot directly into a touch-friendly browser session with no desktop environment?
2. How should we implement and secure the license validation service using the provided URL (e.g., periodic checks, logging, failure handling)?
3. What is the best approach to ensure reliable touch support (drivers, libinput tweaks, onboard keyboard configuration) on Chromeboxes and typical AIO hardware?
4. What branding steps (Plymouth theme, splash image, kiosk browser chrome) are necessary for a consistent look-and-feel?
5. Identify risks, prior issues (scroll/touch bugs), and mitigation strategies.
6. Recommend specialist personas (roles and focus) needed to execute the build.

## Deliverables
- Populate `02_INTEL/README.md` with:
  - Executive summary of findings
  - Detailed notes for each key question above
  - References/links to relevant docs and tooling
  - List of recommended specialist personas with justifications

## Constraints & Notes
- Base OS: Ubuntu Server 22.04 LTS Minimal
- Browser: Firefox in kiosk mode (override if research suggests better option)
- License URL: read from `00_PLACE START FILE HERE/New Text Document.txt`
- Hardware targets: mrchromebox flashed Chromeboxes and common AIO PCs (touch panels).

Confirm completion to the Project Manager when `02_INTEL/README.md` is ready.
