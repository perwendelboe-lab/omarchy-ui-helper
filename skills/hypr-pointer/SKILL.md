---
name: hypr-pointer
description: Move, click, scroll and drag the mouse on the user's Omarchy/Hyprland computer with verification. Use when accessibility (Cua Driver) actions are not possible.
---
# Pointer (remote)
Run via Shell with the user's Omarchy `machineId`. Coordinates are **logical** px (`hyprctl cursorpos`); screenshots are physical px — `hypr-hands geom` shows scale/offset, `ocr-find` already returns logical coords.

```bash
export HYPR_HANDS_REQUIRE_CLASS=<target-class-prefix>   # always
hypr-hands move X Y             # Lua hl.dsp.cursor.move + ±2px verify (exit 4 on mismatch)
hypr-hands click [left|right|middle] [X Y]   # wlrctl; exit 5 = no backend, 3 = locked, 8 = guard
hypr-hands scroll up|down|left|right [steps] # 15 units = 1 wheel notch
HYPR_HANDS_ALLOW_UINPUT=1 hypr-hands drag X1 Y1 X2 Y2   # ydotool button hold; needs ydotoold
```
Notes: `move` auto-selects Lua `hl.dsp.cursor.move` (Omarchy 4.x) or classic `hyprctl dispatch movecursor X Y` (hyprland.conf setups); classic `dispatch movecursor` fails on Lua-config Hyprland; wlrctl cannot hold a button, so drag needs ydotool (opt-in). To move windows use `hypr-hands windows`, not drag. Record the cursor first and restore it after.
