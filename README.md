<p align="center"><img src="assets/logo.png" width="96" alt="logo"></p>

# Omarchy UI Helper — a Grok Bot for driving Omarchy/Hyprland desktops

A Grok Bot template plus the **hypr-hands** toolkit (skills + bash scripts, Agent Plugins `plugin.json` format) that lets a Grok Bot operate your Omarchy / Hyprland (Wayland) computer remotely: look at the screen, find text, move/click/scroll/drag, type and send shortcuts, use the clipboard, manage windows and drive Omarchy menus — accessibility-first through [Cua Driver](https://github.com/trycua/cua), with a verified pointer/keyboard fallback.

## What it does

| Skill | Purpose |
|---|---|
| `hypr-computer-use` | The overall loop: run on your machine via Shell + machineId, Cua Driver first, pointer fallback, observe → act → verify, safety rules |
| `hypr-pointer` | Verified cursor moves, clicks, scrolls, drags |
| `hypr-windows` | List / focus / move to workspace / fullscreen / close via Hyprland Lua dispatch |
| `omarchy-menus` | Keyboard-driven Omarchy menus (keybindings menu → filter → Return) |
| `screen-read` | Screenshots, OCR text location, clipboard, desktop summary |
| `cua-driver-local-computer-use` | Driving native apps with `cua-driver` (AT-SPI element tokens, sessions) |
| `omarchy` | End-user Omarchy/Hyprland customization (config locations, `omarchy` CLI, safety) |

On the machine you get `~/.local/share/hypr-hands/scripts/*.sh` and a `hypr-hands` CLI in `~/.local/bin`:
`hypr-hands check | describe | geom | move X Y | click [btn] [X Y] | scroll DIR [n] | drag X1 Y1 X2 Y2 | type TEXT | key COMBO | shot | ocr-find TEXT | clip get|set | windows … | wait-window CLASS | update-check | breaking-watch | setup`.

## Quick start

1. **Create the bot** from the Grok Bot template: TEMPLATE_LINK
2. **Connect your Omarchy computer** to Grok Bot (install the Grok Bot desktop app on it and register the machine).
3. **Ask the bot to set itself up.** It runs the installer on your machine for you (`install.sh --yes --no-packages`) and tells you the one-line `sudo pacman …` / `yay …` command for anything missing (sudo needs your terminal).

Manual install on the Omarchy machine:

```bash
git clone https://github.com/perwendelboe-lab/omarchy-ui-helper ~/code/omarchy-ui-helper && ~/code/omarchy-ui-helper/install.sh
```
`install.sh` flags: `--dry-run`, `--yes`/`--non-interactive`, `--with-cua`, `--with-ydotool`, `--no-packages`, `--no-copy`. Steps: detect Omarchy/Hyprland/Wayland → pacman packages (`grim slurp wl-clipboard tesseract tesseract-data-eng jq wtype`) → `yay -S aur/wlrctl` → optional Cua Driver → optional ydotool → copy to `~/.local/share/hypr-hands` + `hypr-hands` CLI → `hypr-hands check`.
Update: `git -C ~/code/omarchy-ui-helper pull && ~/code/omarchy-ui-helper/install.sh --yes --no-packages`. Remove: `./uninstall.sh` (`--ydotool`, `--cua`, `--packages`, `--dry-run`).

## Compatibility (Omarchy channels)

| | Edge / dev (tested) | Stable 4.0.x | Omarchy 3.x / plain Hyprland `.conf` |
|---|---|---|---|
| Hyprland | 0.56.2 (Lua config) | 0.56.2 (Lua config) | classic hyprlang |
| Dispatch used | `hyprctl repl` + `hl.dsp.*` | same | `hyprctl dispatch …` (auto-detected; untested live) |
| `omarchy-menu-keybindings`, `omarchy` CLI, `omarchy-menu` layer, `/usr/share/omarchy/default/agents/skills/omarchy` | ✅ | ✅ | menus differ; not covered |
| Packages (grim, wtype, tesseract, ydotool from Arch/Omarchy mirrors; wlrctl from AUR) | ✅ | ✅ | ✅ |

Force a style with `HYPR_HANDS_DISPATCH=lua|classic`; `HYPR_HANDS_DRYRUN=1` prints dispatch commands instead of running them.

## Cua Driver (recommended)

Install (official, no sudo, to `~/.local/bin/cua-driver`):
```bash
/bin/bash -c "$(curl -fsSL https://cua.ai/driver/install.sh)"
```
systemd user unit with Wayland enabled (`install.sh --with-cua` writes it):
```ini
# ~/.config/systemd/user/cua-driver.service
[Unit]
Description=Cua Driver daemon
After=graphical-session.target
[Service]
Type=simple
Environment=CUA_DRIVER_RS_ENABLE_WAYLAND=1
Environment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin
ExecStartPre=/bin/mkdir -p %h/.cache/cua-driver
ExecStart=%h/.local/bin/cua-driver serve --socket %h/.cache/cua-driver/cua-driver.sock
Restart=on-failure
RestartSec=2
[Install]
WantedBy=default.target
```
`systemctl --user daemon-reload && systemctl --user enable --now cua-driver.service && cua-driver doctor`.
Update: `cua-driver update --apply && systemctl --user restart cua-driver.service`.

## Optional: ydotool (drag + fallback click/scroll) — default off

- **Enables:** `drag` (button hold; wlrctl can only click) and click/scroll when wlrctl is missing.
- **Risk:** system-wide input injection through `/dev/uinput`; anything in the `input` group can type/click into any window. hypr-hands only uses it with `HYPR_HANDS_ALLOW_UINPUT=1`.
- **Setup:**
  ```bash
  sudo pacman -S ydotool
  echo 'KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/80-uinput.rules
  sudo udevadm control --reload-rules && sudo udevadm trigger --name-match=uinput
  sudo usermod -aG input "$USER"            # then log out/in or reboot
  systemctl --user enable --now ydotool.service   # socket: $XDG_RUNTIME_DIR/.ydotool_socket
  ```
- **Undo:** `./uninstall.sh --ydotool`.

## Update checks + weekly routine

- `hypr-hands update-check [--json] [--apply]` — cua-driver, Omarchy (incl. dev channel), Hyprland, wlrctl, ydotool and hypr-hands itself (installed copy or clone vs GitHub `main`); flags major bumps. `--apply` only runs the sudo-free `cua-driver update --apply`.
- `hypr-hands breaking-watch [--json]` — release notes (cua-driver, Hyprland) and Omarchy commits since your installed version, scanned for breaking/Lua/dispatch/Wayland/uinput keywords.
- Add a weekly Grok Bot routine with the prompt in [`docs/routine-prompt.md`](docs/routine-prompt.md).

## Safety

- Everything runs on *your* machine only through the bot's Shell tool with your machineId; the bot asks before taking over your pointer/keyboard.
- **Target guard:** `HYPR_HANDS_REQUIRE_CLASS=<prefix>` — click/scroll/drag refuse unless the focused window and the window under the cursor match; type/key require the focused window (exit 8).
- **Locked screen:** input refused while `hyprlock` runs (exit 3). **Verified pointer:** ±2 px `cursorpos` check (exit 4). **Secrets:** `type` refuses secret-looking text (exit 6).
- **uinput opt-in:** ydotool only with `HYPR_HANDS_ALLOW_UINPUT=1`. The bot never runs sudo; installs needing root are handed to you.
- Backend order: Cua Driver (accessibility) → Lua cursor move + `wlrctl` → `hypruse` → `ydotool` (opt-in).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `hyprctl dispatch movecursor 100 100` → Lua `')' expected` | Lua-config Hyprland routes `dispatch` through `hl.dispatch`. Use `hyprctl repl "hl.dispatch(hl.dsp.cursor.move({ x = 100, y = 100 })); return 'ok'"` (named fields). Also `hl.dsp.focus({ window = 'address:0x…' })`, `hl.dsp.window.move({ workspace = '3', follow = false })`, `hl.dsp.window.fullscreen()`, `hl.dsp.window.close()`. |
| `/dev/uinput` not writable after setup | New login needed for the `input` group; check `id -nG`. |
| ydotool "failed to connect socket" | Arch user unit uses `$XDG_RUNTIME_DIR/.ydotool_socket`; scripts auto-detect, else `export YDOTOOL_SOCKET=…`. |
| `yay -S wlrctl` says "nothing to do" | Use `yay -S aur/wlrctl`. |
| `hypr-hands: command not found` | Add `~/.local/bin` to PATH or call `~/.local/share/hypr-hands/bin/hypr-hands`. |
| `click` exit 5 "no click backend" | Install wlrctl or opt in to ydotool. |
| sudo/pacman hangs when the bot runs it | No TTY for the password; run that command yourself. |
| `dispatch failed` (exit 9) | Wrong dispatch style forced or detected; unset `HYPR_HANDS_DISPATCH` and check `hypr-hands check` → `dispatch`. |
| HiDPI coordinates off | Scripts use logical px; screenshots are physical; see `hypr-hands geom`. |

## Tested matrix (v0.3.1)

Omarchy 4.0.0 (dev), Hyprland 0.56.2 (Lua config), eDP-1 1920×1080 @1.5, wlrctl 0.2.2, ydotool 1.0.4, cua-driver 0.30.1, driven remotely by Grok Bot.

| Feature | Status |
|---|---|
| move (Lua `cursor.move`) + ±2 px verify | ✅ |
| click left/right/middle (wlrctl); ydotool fallback | ✅ (foot mouse log, GTK4 button) |
| scroll 4 directions | ✅ |
| drag (Lua moves + ydotool down/up) | ✅ (GTK4 GestureDrag exact) |
| type / key incl. chords | ✅ (raw byte log) |
| target guard, secret refusal | ✅ · lock refusal ⚠️ not exercised live |
| shot full, ocr-find, clip | ✅ · shot region/select/window ⚠️ untested |
| windows list/focus/move/fullscreen/close | ✅ |
| Omarchy keybindings menu flow | ✅ |
| install.sh (dry-run + real `--yes --no-packages`), update-check, breaking-watch | ✅ · fresh-machine install with packages ⚠️ untested |
| hypruse backend | ⚠️ untested |

## License

MIT © 2026 PWN. The bundled `omarchy` skill is adapted from Omarchy (MIT). Cua Driver is a separate project by trycua under its own license.
