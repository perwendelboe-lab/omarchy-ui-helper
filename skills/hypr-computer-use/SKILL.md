---
name: hypr-computer-use
description: Operate the user's Omarchy/Hyprland (Wayland) desktop remotely - observe, click, type, scroll, manage windows. Use when asked to do something in a GUI app on their Omarchy computer.
---
# Omarchy computer use (remote)

You drive the user's Omarchy computer from Grok Bot. **Every command runs through your Shell tool with `machineId` = the user's Omarchy machine** (find it with `ListMachines`; prefer the machine the message came from or the one they name). Never run these on your own box.

Tools: `hypr-hands <cmd> [args]` (CLI in `~/.local/bin`) = `~/.local/share/hypr-hands/scripts/<cmd>.sh`. All print JSON; nonzero exit = refused/failed. If missing, install: `git clone https://github.com/perwendelboe-lab/omarchy-ui-helper ~/code/omarchy-ui-helper && ~/code/omarchy-ui-helper/install.sh --yes --no-packages` (ask first; packages need the user's sudo).

## Compatibility
Omarchy stable (4.0.0–4.0.6) and edge/dev both use Hyprland 0.56 with Lua config (`hyprctl repl` + `hl.dsp.*`); 4.0.5 and 4.0.6 changed nothing hypr-hands relies on. Older Omarchy 3.x / plain Hyprland with `hyprland.conf` uses classic `hyprctl dispatch`; the scripts auto-detect (`hypr-hands check` → `"dispatch":"lua"|"classic"`; force with `HYPR_HANDS_DISPATCH=lua|classic`).

## Grok Bot desktop app
Some Omarchy versions do not preinstall the Grok Bot app. `hypr-hands grokbot status` reports whether it is installed and running and whether the `grokbot` launcher and keybinding exist. If the user asks to open Grok Bot, run `grokbot` (focuses the running window, else launches it; never moves or resizes windows). If it is missing, do not install it yourself: show the output of `hypr-hands grokbot install-help` (Omarchy repo `omarchy-pkg-add grok-bot`, or Omarchy's PKGBUILD with `makepkg -si`), since both need the user's sudo. Never suggest AUR packages or AUR helpers (yay, paru, `grok-bot-desktop`, debtap): the AUR has had malware incidents and runs arbitrary build scripts. If the user asks about the AUR, say it is not recommended and offer the official routes. Add the Super+Ctrl+G binding only when asked: `hypr-hands grokbot bind --dry-run` first, then `hypr-hands grokbot bind`.

## Backend order
1. **Cua Driver first** (skill `cua-driver-local-computer-use`): accessibility actions, no pointer takeover. End with `end_session`.
2. **Pointer/keyboard fallback**: `hypr-hands move|click|scroll|drag|type|key` (wlrctl for click/scroll; ydotool only with `HYPR_HANDS_ALLOW_UINPUT=1`).
3. **Drag**: `hypr-hands drag` uses the Cua Driver desktop drag first (`backend:"cua-driver-vptr"`, a real held press over the Wayland virtual pointer) when the cua-driver daemon runs, and falls back to ydotool only with `HYPR_HANDS_ALLOW_UINPUT=1`. `hypr-hands check` → `drag_backend` shows which one applies. A drag takes over the user's pointer, so ask first.

## Loop: observe → act → verify
1. `hypr-hands check` once; `hypr-hands describe` / `geom` to observe; `shot` + `ocr-find TEXT` to locate (read screenshots with Read + machineId).
2. One small action at a time.
3. Verify (`describe`, new screenshot, `wait-window CLASS`). Never chain blind actions.

## Window management
`hypr-hands windows list|focus|move|fullscreen|close|float|resize|moveto|center|swap|movedir|focusdir|pseudo|split|snapshot|restore` (skill `hypr-windows` has the syntax). Before any rearranging, run `hypr-hands windows snapshot` and note the file; afterwards offer the user `hypr-hands windows restore FILE` to undo. Verify each change with `hypr-hands windows list`.

## Safety rules
- Ask before taking over the user's pointer/keyboard (they may be using the machine).
- Set `HYPR_HANDS_REQUIRE_CLASS=<target class prefix>` on every input command: scripts refuse (exit 8) unless the focused window — and for pointer actions the window under the cursor — matches.
- Never act on a locked screen (scripts refuse while `hyprlock` runs).
- Verify cursor position before clicks (`click left X Y` does it, ±2px).
- Never type secrets (`type` refuses secret-looking text).
- ydotool/uinput is opt-in; drag needs no uinput when Cua Driver is running. Drags with modifier keys held are refused. Never run sudo/pacman yourself (no TTY; they hang) — give the user the command.
- Don't close or move windows you didn't open (ask first); snapshot before rearranging and offer restore after; record and restore the cursor position and focus.
