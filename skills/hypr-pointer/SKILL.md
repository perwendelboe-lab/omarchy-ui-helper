---
name: hypr-pointer
description: Move, click, scroll and drag the mouse on the user's Omarchy/Hyprland computer with verification. Use when accessibility (Cua Driver) actions are not possible.
---
# Pointer (remote)
Run via Shell with the user's Omarchy `machineId`. Coordinates are **logical** px (`hyprctl cursorpos`); screenshots are physical px — `hypr-hands geom` shows scale/offset, `ocr-find` already returns logical coords.

```bash
export HYPR_HANDS_REQUIRE_CLASS=<target-class-prefix>   # always
hypr-hands move X Y             # Lua hl.dsp.cursor.move + ±2px verify (exit 4 on mismatch)
hypr-hands click [left|right|middle] [X Y]   # needs a backend (ydotool opt-in, hypruse, or existing wlrctl; never install wlrctl, it is AUR-only); exit 5 = no backend, 3 = locked, 8 = guard
hypr-hands scroll up|down|left|right [steps] # 15 units = 1 wheel notch
hypr-hands drag X1 Y1 X2 Y2 [steps]          # Cua Driver held drag first; JSON says "backend"
HYPR_HANDS_ALLOW_UINPUT=1 hypr-hands drag X1 Y1 X2 Y2   # also allows the ydotool fallback
```
Drag: `hypr-hands check` → `drag_backend` tells you what drag will use. `cua-driver-vptr` = Cua Driver desktop-scope drag over the Wayland virtual pointer (one press at the start, held motion, one release at the end). It needs the `cua-driver` daemon running with `CUA_DRIVER_RS_ENABLE_WAYLAND=1`. hypr-hands converts logical px to Cua's physical desktop frame, moves to the start, applies the target guard, and verifies the end position (exit 4 on mismatch, 11 if Cua fails after starting). It uses Cua automatically only with one monitor; `HYPR_HANDS_DRAG_BACKEND=cua|ydotool|auto` forces a backend. Without Cua, drag falls back to ydotool only with `HYPR_HANDS_ALLOW_UINPUT=1`; otherwise exit 5. Drags with modifier keys held are refused. Duration: `HYPR_HANDS_DRAG_MS` (default 500).

Notes: `move` auto-selects Lua `hl.dsp.cursor.move` (Omarchy 4.x) or classic `hyprctl dispatch movecursor X Y` (hyprland.conf setups); classic `dispatch movecursor` fails on Lua-config Hyprland; wlrctl cannot hold a button, so drag uses Cua (or opt-in ydotool). A drag takes over the real pointer, so ask first. To move windows use `hypr-hands windows`, not drag. Record the cursor first and restore it after.
