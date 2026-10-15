---
name: hypr-computer-use
description: Operate the user's Omarchy/Hyprland (Wayland) desktop - observe, click, type, manage windows. Use when asked to do something in a GUI app on Linux/Hyprland.
---
# Hyprland computer use

Scripts live in `scripts/` at the plugin root (e.g. `~/.cursor/plugins/local/hypr-hands/scripts`). All emit JSON or plain paths; nonzero exit = refused/failed.

## Order of backends
1. **cua-driver first** (`~/.local/bin/cua-driver`, MCP or `cua-driver call ...`): accessibility tree actions don't steal the pointer. Always finish with `end_session`.
2. **Pointer fallback**: `move.sh` (Lua `hl.dsp.cursor.move`) + `click.sh` (wlrctl → hypruse → ydotool only if `HYPR_HANDS_ALLOW_UINPUT=1`).
3. Keyboard: `type.sh`, `key.sh` (wtype).

## Loop: observe → act → verify
1. `check.sh` once; `describe.sh` / `geom.sh` to observe; `shot.sh` + `ocr-find.sh TEXT` to locate.
2. Act with one small step.
3. Verify (new `describe.sh`, screenshot, `wait-window.sh`). Never chain blind actions.

## Safety rules
- Ask the user before taking over the foreground pointer/keyboard.
- Never act while the screen is locked (scripts refuse if `hyprlock` runs).
- Verify cursorpos before every click (`click.sh btn X Y` does it, ±2px).
- Never type secrets; `type.sh` refuses secret-looking text.
- ydotool/uinput is opt-in only; never change system permissions or install packages yourself — print `setup.sh` output.
- Don't close or move windows you didn't open.
