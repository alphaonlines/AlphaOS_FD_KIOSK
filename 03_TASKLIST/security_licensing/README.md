# Security & Licensing – Task Notes

## Objective
Deliver a hardened license validation workflow for AlphaOS kiosks so each device periodically confirms entitlement using the Shopify-hosted URL stored in `/etc/alphaos/license-url`. The solution must remain resilient to transient network loss, emit actionable logs, and integrate cleanly with the image build process scripted by the Platform Engineer.

## Planned Components
1. **`/opt/alphaos/license-check.sh`** – Oneshoot bash script run by systemd. Responsibilities:
   - Read the canonical URL from `/etc/alphaos/license-url`.
   - Fetch remote JSON/text via `curl` with TLS 1.2+, certificate pinning (optional placeholder) and strict protocol flags.
   - Validate payload signature/hash (initial version: SHA256 token comparison, extension points for signed JSON).
   - Persist state under `/var/lib/alphaos/license-state.json` (timestamp, result, grace counter).
   - Update `/run/alphaos/license-status` socket/pipe for the kiosk session overlay.

2. **`alphaos-license-check.service`** – Oneshoot unit running as dedicated `alphaos-licd` user with `ReadOnlyPaths=/` and `ReadWritePaths=/var/lib/alphaos`. Exposes structured logging via `systemd-cat`.

3. **`alphaos-license-check.timer`** – Triggers the service 30s after boot and every 15 minutes thereafter. Includes randomized jitter to avoid stampeding the Shopify endpoint.

4. **`/opt/alphaos/license-image-check.sh`** – Lightweight availability probe that confirms the Shopify-hosted license *image* resolves (HTTP 200 + image content-type). Stores its state separately and is scheduled every two weeks to provide early warning if the asset moves or is deleted.

5. **`alphaos-license-image-check.service` + `.timer`** – Runs as `alphaos-licd`, shares the sandbox profile, and fires on the 1st and 15th of each month (~every 2 weeks).

6. **Grace Policy** – Allow kiosks to keep running for up to 16 consecutive failed checks (~4 hours) before signaling the session to block access. Cache last known good response to survive offline windows.

## Integration Hooks
- Build script (`alphaos-build.sh`) copies the license files into the rootfs, ensures `/var/lib/alphaos` ownership (`alphaos-licd:alphaos-licd`), and enables the timer.
- Session script reads `/run/alphaos/license-status` to display warnings; failure escalation handled via Firefox overlay injected by Brand/UX specialist.

## Open Items
- Finalize payload format + signature verification method once Shopify endpoint contract is published.
- Determine how kiosks should surface "Activation lost" UI (toast vs full-screen interstitial).
