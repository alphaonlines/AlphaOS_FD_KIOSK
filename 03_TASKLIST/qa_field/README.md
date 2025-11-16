# QA & Field Reliability Harness

## Objectives (Task 6)
- Validate kiosk boot flow, touch interaction, license grace policy, and kiosk-escape mitigations before field deployment.
- Supply repeatable regression cases for Chromebox (mrchromebox) + AIO targets.
- Capture telemetry (`journalctl`, `/run/alphaos/license-status`, touch logs) and push findings into `06_BUGS`.

## Test Matrix
| ID | Area | Scenario | Expected Result | Notes |
|---|---|---|---|---|
| TCH-01 | Touch | 10-point multi-touch swipe, pinch, long-press | No ghost touches; Onboard pops on text fields | Record `libinput debug-events` trace |
| TCH-02 | Touch | Onboard visibility toggle (launch/close via session hotkey) | Keyboard reappears within 1s, no focus loss | Watch `onboard` DBus logs |
| LIC-01 | Licensing | Disconnect network for 1 interval | `/run/alphaos/license-status` shows FAIL+remaining, zenity warning appears | Use `qa-license-grace-test.sh` to log |
| LIC-02 | Licensing | Repeat failure beyond GRACE_LIMIT | Session should log “grace window exhausted”; kiosk blocks | Requires controlled Shopify mock or host entry |
| SEC-01 | Escape | Attempt Ctrl+Alt+Fx, Alt+Tab, Ctrl+Alt+Backspace | Inputs ignored; no tty switch | Verify `systemctl status getty@tty2` remains inactive |
| UX-01 | Branding | Boot + shutdown cycle | Plymouth splash centered, no tearing; Firefox policies applied | Confirm homepage locked, context menu disabled |
| QA-LOG | Telemetry | Capture `journalctl -b`, `/var/lib/alphaos/license-state.json`, `~kiosk/.local/share/alphaos-qa` | Artifacts attached to SITREP or `06_BUGS` | Scripted via harness |

## Harness Components
- `qa-license-grace-test.sh` – polls `/run/alphaos/license-status` and emits CSV of status transitions to help verify warnings and grace countdown.
- Touch capture checklist (planned) – run `libinput record` + `evtest` while executing TCH cases.
- Escape attempt log – simple script (TBD) to simulate forbidden key combos and ensure journald sees no VT switch.

## Workflow
1. Provision test hardware with latest image.
2. Run harness scripts (license + touch) while executing matrix.
3. File findings in `06_BUGS/bugs.md` and log summary in SITREP.
4. Once matrix passes on both hardware classes, mark Task 6 complete.
