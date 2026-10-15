---
name: hypr-pointer
description: Move, click, scroll and drag the mouse pointer on Hyprland with verification. Use when an accessibility action is not possible.
---
# Pointer
Coordinates are **logical** layout px (what `hyprctl cursorpos` reports). Screenshots are physical px: divide by monitor scale and add monitor x/y (`geom.sh` shows both).

- `scripts/move.sh X Y` — Lua `hl.dispatch(hl.dsp.cursor.move({x=X,y=Y}))`, then verifies ±2px (exit 4 otherwise). Classic `hyprctl dispatch movecursor` fails on Lua-config Hyprland.
- `scripts/click.sh [left|right|middle] [X Y]` — moves+verifies then clicks. Exit 5 = no backend (install wlrctl), exit 3 = locked.
- `scripts/scroll.sh up|down [n]` — wlrctl / ydotool; falls back to PageUp/PageDown keys.
- `scripts/drag.sh X1 Y1 X2 Y2` — needs ydotool opt-in; to move windows use `windows.sh` instead.
Record the cursor before acting and restore it roughly afterwards.


Tested: click left/right/middle (wlrctl), scroll all four directions (15 units = 1 notch; apps may emit several events per notch). Drag untested (ydotool-only).
Set `HYPR_HANDS_REQUIRE_CLASS=prefix` to hard-guard the target window.
