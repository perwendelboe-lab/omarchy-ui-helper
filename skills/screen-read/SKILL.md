---
name: screen-read
description: Read the user's Omarchy/Hyprland screen remotely - screenshots (grim), OCR text location (tesseract), clipboard (wl-clipboard), desktop summary.
---
# Screen read (remote)
Run via Shell with the user's Omarchy `machineId`.

```bash
hypr-hands describe                     # monitors, active window, windows per workspace
hypr-hands shot [full|window|region "X,Y WxH"] [out]   # prints PNG path (physical px)
hypr-hands ocr-find TEXT                # JSON matches with logical centre coords for `click left X Y`
hypr-hands clip get | clip set TEXT
```
To look at a screenshot: Read the printed path with the same `machineId` (or CopyToBox, then Read). Save and restore the user's clipboard if you change it. Screenshots may contain private data — don't upload or share them.
