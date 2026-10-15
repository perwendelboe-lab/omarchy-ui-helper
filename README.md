# Hypr Hands

Computer use for **Omarchy / Hyprland (Wayland)** as a Cursor plugin: skills + bash scripts that let an agent observe the desktop, move the pointer, click, scroll, drag, type, send shortcuts, take screenshots, OCR the screen, use the clipboard and manage windows.

## Requirements
Required: `hyprland` (hyprctl with Lua `repl`), `jq`, `wtype`, `grim`, `wl-clipboard`.
Optional: `slurp` (region select), `tesseract` + `tesseract-data-eng` (OCR), a click backend (below), `cua-driver` (accessibility-first automation).

```bash
sudo pacman -S --needed jq wtype grim slurp wl-clipboard tesseract tesseract-data-eng
yay -S wlrctl          # AUR: virtual-pointer click backend (preferred)
sudo pacman -S ydotool # optional, needs /dev/uinput access; opt-in only
# hypruse (optional, needs uv): sudo pacman -S uv ; then uvx hypruse
```
Run `scripts/setup.sh` to print these for your machine; it installs nothing. `scripts/check.sh` reports what is present.

## Install (local)
```bash
git clone <repo> ~/code/hypr-hands
ln -s ~/code/hypr-hands ~/.cursor/plugins/local/hypr-hands
```

## Backend order
1. **cua-driver** accessibility tools (when the target app exposes AT-SPI) — no pointer takeover.
2. Pointer: cursor move via `hyprctl repl` → `hl.dsp.cursor.move({x=,y=})` (classic `hyprctl dispatch movecursor` is not accepted on Lua-config Hyprland).
3. Click: `wlrctl pointer` (virtual pointer) → `hypruse` → `ydotool` **only** with `HYPR_HANDS_ALLOW_UINPUT=1`.
4. Keyboard: `wtype`; shortcuts via `hl.dsp.send_shortcut` or `wtype -M/-k`.

## Safety model
- Never acts while `hyprlock` is running.
- Ask the user before taking over the foreground pointer/keyboard.
- Verify `cursorpos` (±2px) before clicking.
- `type.sh` refuses secret-looking text unless `--i-know-this-is-not-a-secret`.
- uinput/ydotool is opt-in; nothing changes system permissions.
- End cua-driver sessions with `end_session`.

No `mcp.json` ships: hypruse was not present on the dev machine. If you install it you can add it as an MCP server yourself.

## Guard for automated tests / sandboxes
Set `HYPR_HANDS_REQUIRE_CLASS=<prefix>` and `click.sh`, `scroll.sh`, `type.sh` and `key.sh` refuse (exit 8) unless the focused window (and, for pointer actions, the window under the cursor) has a class starting with that prefix.

## Tested status (v0.1.0, Omarchy, Hyprland Lua config, eDP-1 1920x1080 @1.5)
| Feature | Status |
|---|---|
| move.sh (Lua `hl.dsp.cursor.move`) + ±2px verify | tested |
| click.sh left/right/middle via `wlrctl pointer click` | tested (foot mouse log + GTK4 button) |
| scroll.sh up/down/left/right via `wlrctl pointer scroll <dy> <dx>`, step = 15 units (one libinput notch) | tested |
| drag.sh: Lua absolute moves + `ydotool click 0x40/0x80` (needs HYPR_HANDS_ALLOW_UINPUT=1, ydotoold) | tested (GTK4 GestureDrag 100,150 → 400,450 exact) |
| click.sh ydotool fallback when wlrctl absent | tested |
| type.sh / key.sh (wtype, chords incl. ctrl+shift) | tested |
| shot.sh full, ocr-find.sh, clip.sh, geom/describe/check | tested |
| windows.sh list/focus/move/fullscreen/close | tested |
| omarchy-menus: `omarchy-menu-keybindings` → type filter → Return | tested (toggled fullscreen) |
| shot.sh region/select/window, hypruse backend | not tested |

### ydotool (opt-in)
`sudo pacman -S ydotool`, give your user `/dev/uinput` access (e.g. udev rule `KERNEL=="uinput", GROUP="input", MODE="0660"` + `input` group), then `systemctl --user enable --now ydotool.service`. The Arch user unit's socket is `$XDG_RUNTIME_DIR/.ydotool_socket`; `lib.sh` finds it (or honours `$YDOTOOL_SOCKET`, then `/tmp/.ydotool_socket`).
