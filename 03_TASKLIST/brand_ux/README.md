# Brand & UX Payloads

## Plymouth Theme – `alpha-kiosk`
- Source: `03_TASKLIST/brand_ux/plymouth/`
  - `alpha-kiosk.plymouth` descriptor
  - `alpha-kiosk.script` centering/scale logic
  - `assets/splash.png` (AlphaOS artwork)
- Install path: `/usr/share/plymouth/themes/alpha-kiosk/`
- Activation: `plymouth-set-default-theme alpha-kiosk` followed by `update-initramfs -u`

## Firefox Policies
- File: `03_TASKLIST/brand_ux/firefox/policies.json`
- Enforces kiosk defaults (home URL, kiosk mode toggles, disables updates/about pages, blocks context menu & downloads).
- Copy to `/usr/lib/firefox/distribution/policies.json` and `/usr/lib/firefox-esr/distribution/policies.json` during image build to cover both package variants.
