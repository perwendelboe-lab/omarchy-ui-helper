<p align="center"><img src="assets/logo.png" width="96" alt="hypr-hands logo"></p>

# Hypr Hands

**Computer use for Omarchy / Hyprland (Wayland).** A Cursor plugin (Cursor Plugin + Agent Plugins manifests) that gives an AI agent safe "hands" on a Hyprland desktop: observe the screen, find text, move/click/scroll/drag the pointer, type and send shortcuts, use the clipboard, manage windows, and drive Omarchy menus. Pairs with [Cua Driver](https://github.com/trycua/cua) for accessibility-first automation and bundles Omarchy's own customization skill.

It is also the recipe for a **Grok Bot** that operates an Omarchy machine (see [Recreate the Grok Bot](#recreate-the-grok-bot)).

## What you get

| Skill | Purpose |
|---|---|
| `hypr-computer-use` | The overall loop: Cua Driver accessibility first, pointer fallback, observe → act → verify, safety rules |
| `hypr-pointer` | Verified cursor moves, clicks, scrolls, drags |
| `hypr-windows` | List / focus / move to workspace / fullscreen / close via Lua dispatch |
| `omarchy-menus` | Keyboard-driven Omarchy menus (e.g. keybindings menu → filter → Return) |
| `screen-read` | Screenshots, OCR text location, clipboard |
| `cua-driver-local-computer-use` | Driving native apps through `cua-driver` (AT-SPI tokens, sessions) |
| `omarchy` | End-user Omarchy/Hyprland customization (config locations, `omarchy` CLI, safety) |

Scripts (`scripts/`, bash, JSON output): `check` `setup` `geom` `describe` `move` `click` `scroll` `drag` `type` `key` `shot` `ocr-find` `clip` `windows` `wait-window` `update-check` `breaking-watch`.

## Requirements

- Arch-based system with **Hyprland** (tested 0.56.2 with Lua config, i.e. `hyprctl repl` + `hl.dsp.*`) on Wayland — Omarchy 4.x recommended.
- Required packages: `grim slurp wl-clipboard tesseract tesseract-data-eng jq wtype` (pacman), `wlrctl` (AUR).
- Optional: Cua Driver (`~/.local/bin/cua-driver` + user service), `ydotool` (drag; opt-in).

## Quick install

```bash
git clone https://github.com/<you>/hypr-hands ~/code/hypr-hands
cd ~/code/hypr-hands
./install.sh --dry-run     # see exactly what would happen
./install.sh               # interactive; or --yes for defaults (optional steps off)
```
Then restart Cursor (or *Developer: Reload Window*) and check **Customize → Skills**.

## Step-by-step setup

1. **Packages** — `sudo pacman -S --needed grim slurp wl-clipboard tesseract tesseract-data-eng jq wtype`
2. **Click backend** — `yay -S aur/wlrctl` (virtual-pointer protocol; no special permissions).
3. **Cua Driver (optional, recommended)** — official installer, no sudo:
   ```bash
   /bin/bash -c "$(curl -fsSL https://cua.ai/driver/install.sh)"
   ```
   then a systemd **user** unit (`install.sh` writes it):
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
   `systemctl --user daemon-reload && systemctl --user enable --now cua-driver.service`, then `cua-driver doctor`. Update later with `cua-driver update --apply`.
4. **Plugin** — `install.sh` copies the repo into `~/.cursor/plugins/local/hypr-hands` (Cursor ignores symlinks there that point outside the folder). Re-run it after `git pull`.
5. **Verify** — `scripts/check.sh` → expect `"click_backend":"wlrctl"`, `"lua_repl":true`.

### Optional: ydotool (drag + fallback click/scroll) — default off

- **Enables:** `drag.sh` (button hold — wlrctl can only click), and click/scroll when wlrctl is missing.
- **Risk:** ydotool injects input system-wide via `/dev/uinput`; any process in the `input` group can type/click into *any* window. hypr-hands only uses it when `HYPR_HANDS_ALLOW_UINPUT=1`.
- **Changes:**
  ```bash
  sudo pacman -S ydotool
  echo 'KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"' | sudo tee /etc/udev/rules.d/80-uinput.rules
  sudo udevadm control --reload-rules && sudo udevadm trigger --name-match=uinput
  sudo usermod -aG input "$USER"      # then log out/in (or reboot)
  systemctl --user enable --now ydotool.service   # socket: $XDG_RUNTIME_DIR/.ydotool_socket
  ```
- **Undo:** `./uninstall.sh --ydotool` (disables the unit, removes the rule, drops the group; re-login).

## Recreate the Grok Bot

1. **Create the bot** in Grok Bot (new agent). Suggested name: **Omarchy Hands**; title: *Desktop operator for my Omarchy machine*.
2. **Connect the computer**: install the Grok Bot desktop app on the Omarchy machine and register it, so the bot can run Shell with that machine's `machineId`.
3. **Install the plugin on the machine**: clone this repo and run `./install.sh` (as above). For Cursor on the same machine that's all; for Grok Bot, also import the skills: copy `skills/*` into the bot's skills/workflows (each folder has a `SKILL.md`) or point the bot at this repo.
4. **System profile** (paste into the bot's instructions):
   > You operate my Omarchy (Arch + Hyprland, Wayland) computer through the hypr-hands plugin at `~/.cursor/plugins/local/hypr-hands` and Cua Driver. Always run desktop commands on that machine. Prefer cua-driver accessibility actions; fall back to hypr-hands scripts. Observe → act → verify. Ask before taking over the pointer/keyboard, never act while the screen is locked, set `HYPR_HANDS_REQUIRE_CLASS` to the target window when sending input, never type secrets, never send input to windows you were not asked to use, don't install packages or run sudo without my approval, and end every cua session with `end_session`. Classic `hyprctl dispatch` may fail on this Hyprland — use `hyprctl repl "hl.dispatch(hl.dsp.…)"`.
5. **Routine**: weekly update + breaking-change check using [`docs/routine-prompt.md`](docs/routine-prompt.md).

## Safety model

- **Locked screen:** every input script refuses while `hyprlock` runs (exit 3).
- **Target guard:** `HYPR_HANDS_REQUIRE_CLASS=<prefix>` makes click/scroll/drag refuse unless both the focused window and the window under the cursor match; type/key require the focused window to match (exit 8).
- **Verified pointer:** `move.sh` checks `cursorpos` within ±2 px; `click.sh X Y` / `drag.sh` refuse on mismatch (exit 4).
- **Secrets:** `type.sh` refuses secret-looking text unless `--i-know-this-is-not-a-secret` (exit 6).
- **uinput opt-in:** ydotool used only with `HYPR_HANDS_ALLOW_UINPUT=1`; nothing changes permissions except the explicit installer step.
- **Consent:** skills tell the agent to ask before foreground takeover and never to automate permission dialogs.
- Backend order: Cua Driver (accessibility) → Lua cursor move + `wlrctl` → `hypruse` → `ydotool` (opt-in).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `hyprctl dispatch movecursor 100 100` → Lua `')' expected` error | Hyprland with Lua config routes `dispatch` through `hl.dispatch`. Use `hyprctl repl "hl.dispatch(hl.dsp.cursor.move({ x = 100, y = 100 })); return 'ok'"` (named fields; positional args go to 0,0). Focus: `hl.dsp.focus({ window = 'address:0x…' })`; move: `hl.dsp.window.move({ workspace = '3', follow = false })`; `hl.dsp.window.fullscreen()`, `hl.dsp.window.close()`. |
| `/dev/uinput` still not writable after setup | Group membership needs a new login session — log out/in or reboot; check `id -nG` shows `input`. |
| `ydotool: failed to connect socket` | The Arch user unit listens on `$XDG_RUNTIME_DIR/.ydotool_socket` (not `/tmp/.ydotool_socket`). `lib.sh` auto-detects; for manual use `export YDOTOOL_SOCKET=$XDG_RUNTIME_DIR/.ydotool_socket`. |
| `yay -S wlrctl` says "nothing to do" / picks the wrong package | Use the explicit repo prefix: `yay -S aur/wlrctl`. |
| Skills don't show up in Cursor | Plugin must be a real directory under `~/.cursor/plugins/local/` (symlinks to elsewhere are skipped). Re-run `./install.sh`, reload window; Teams/Enterprise admins must allow local plugin imports. |
| `click.sh` exit 5 "no click backend" | Install wlrctl, or opt in to ydotool. |
| Coordinates off on HiDPI | Scripts use logical px (`hyprctl cursorpos`); screenshots are physical. `ocr-find.sh` converts; see `geom.sh` for scale/offset. |

## Tested matrix (v0.2.0)

Omarchy 4.0.0 (omarchy-dev), Hyprland 0.56.2 (Lua config), eDP-1 1920×1080 @1.5, wlrctl 0.2.2, ydotool 1.0.4, cua-driver 0.30.1.

| Feature | Status | How it was verified |
|---|---|---|
| `move.sh` (Lua `cursor.move`) + ±2 px verify | ✅ | cursorpos matched; out-of-range refused |
| `click.sh` left/right/middle (wlrctl) | ✅ | foot SGR mouse log + GTK4 button log |
| `click.sh` ydotool fallback (wlrctl hidden) | ✅ | GTK4 log |
| `scroll.sh` up/down/left/right | ✅ | foot mouse log (buttons 64/65/66/67) |
| `drag.sh` (Lua moves + ydotool down/up) | ✅ | GTK4 GestureDrag 100,150 → 400,450 exact |
| `type.sh`, `key.sh` incl. ctrl/shift chords | ✅ | raw byte log (`od`) |
| Target guard / lock refusal / secret refusal | ✅ / ⚠️ lock path not exercised live / ✅ | exit codes 8 / – / 6 |
| `shot.sh full`, `ocr-find.sh`, `clip.sh` | ✅ | |
| `shot.sh region/select/window` | ⚠️ untested | |
| `windows.sh` list/focus/move/fullscreen/close | ✅ | `clients -j` workspace + fullscreen 0→2→0 |
| Omarchy keybindings menu flow | ✅ | toggled fullscreen via menu |
| `install.sh --dry-run`, `update-check.sh`, `breaking-watch.sh` | ✅ | |
| `install.sh` real run on a fresh machine | ⚠️ untested | |
| hypruse backend | ⚠️ untested | |

## Update policy

- `scripts/update-check.sh` compares installed versions with upstream (git tags via `git ls-remote`, no API rate limits; pacman/AUR for packages). `--apply` only runs the sudo-free `cua-driver update --apply`.
- `scripts/breaking-watch.sh` scans release notes (cua-driver, Hyprland) and Omarchy commits since your installed version for breaking/Lua/dispatch/Wayland/uinput keywords.
- Run both weekly (see `docs/routine-prompt.md`). Before updating Hyprland or Omarchy, read breaking-watch hits about `hyprctl`/`hl.dsp`; after updating, run `check.sh` and a `move.sh` round-trip.
- hypr-hands itself follows SemVer; see [CHANGELOG.md](CHANGELOG.md).

## Contributing

Issues and PRs welcome. Keep scripts `bash` + `set -euo pipefail`, JSON output, and **never** add code that installs packages, changes permissions or sends input without the existing guards. Test input changes only in disposable windows (`foot --app-id hypr-hands-test`) with `HYPR_HANDS_REQUIRE_CLASS=hypr-hands-test`. Run `shellcheck scripts/*.sh *.sh` before submitting.

## License

MIT © 2026 PWN. The bundled `omarchy` skill is adapted from Omarchy (MIT); Cua Driver is a separate project by trycua with its own license.
