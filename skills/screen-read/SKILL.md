---
name: screen-read
description: Read the screen on Hyprland - screenshots (grim), OCR text location (tesseract), clipboard (wl-clipboard).
---
# Screen read
- `scripts/shot.sh [full|window|region "X,Y WxH"|select] [out]` — prints PNG path (physical px). Read the image to look at it.
- `scripts/ocr-find.sh TEXT` — JSON matches with **logical** centre coords ready for `click.sh left X Y`.
- `scripts/clip.sh get` / `scripts/clip.sh set TEXT` — save and restore the user's clipboard if you change it.
- `scripts/describe.sh` — text summary of monitors, active window, windows per workspace.
Screenshots may contain private data; don't upload them anywhere.


Tested: shot full, ocr-find (logical coords matched click targets), clip round-trip.
