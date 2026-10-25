<p align="center"><img src="assets/logo.png" width="96" alt="logo"></p>

# Omarchy UI Helper — a Grok Bot for driving Omarchy/Hyprland desktops

A Grok Bot template plus the **hypr-hands** toolkit (skills + bash scripts, Agent Plugins `plugin.json` format) that lets a Grok Bot operate your Omarchy / Hyprland (Wayland) computer remotely: look at the screen, find text, move/click/scroll/drag, type and send shortcuts, use the clipboard, manage windows and drive Omarchy menus — accessibility-first through [Cua Driver](https://github.com/trycua/cua), with a verified pointer/keyboard fallback.

## What it does

| Skill | Purpose |
|---|---|
| `hypr-computer-use` | The overall loop: run on your machine via Shell + machineId, Cua Driver first, pointer fallback, observe → act → verify, safety rules |
| `hypr-pointer` | Verified cursor moves, clicks, scrolls, drags |
| `hypr-windows` | List / focus / move / fullscreen / close, float-tile, resize, move-to, center, swap, directional move/focus, pseudo, split, layout snapshot + restore (Lua or classic dispatch) |
| `omarchy-menus` | Keyboard-driven Omarchy menus (keybindings menu → filter → Return) |
| `screen-read` | Screenshots, OCR text location, clipboard, desktop summary |
| `cua-driver-local-computer-use` | Driving native apps with `cua-driver` (AT-SPI element tokens, sessions) |
| `omarchy` | End-user Omarchy/Hyprland customization (config locations, `omarchy` CLI, safety) |

On the machine you get `~/.local/share/hypr-hands/scripts/*.sh` and a `hypr-hands` CLI in `~/.local/bin`:
`hypr-hands check | describe | geom | move X Y | click [btn] [X Y] | scroll DIR [n] | drag X1 Y1 X2 Y2 | type TEXT | key COMBO | shot | ocr-find TEXT | clip get|set | windows … | wait-window CLASS | grokbot [open|status|bind|install-help] | update-check | breaking-watch | setup`, plus a `grokbot` launcher (open or focus the Grok Bot app).

## Install the Grok Bot desktop app first

The Grok Bot desktop app is **not preinstalled on some Omarchy versions** (and never on plain Arch/Hyprland). Grok Bot can only drive a computer that runs the app and is registered as a machine, so install it before anything else. The official Linux build is a `.deb` from xAI ([x.ai/bot](https://x.ai/bot)); on Arch it is repackaged for pacman, never installed with `dpkg`.

**Easiest: ask your Omarchy default agent.** Open it with `omarchy agent` in a terminal (or `Super + Shift + Ctrl + A`, or the console on `Super + Grave`), for example OpenCode, and paste:

```text
Install the Grok Bot desktop app (xAI's official Linux .deb) on this Omarchy machine with pacman.
1. If `pacman -Si grok-bot` finds a package, install it with `omarchy-pkg-add grok-bot` and stop there.
2. Otherwise build Omarchy's recipe, which downloads the official .deb from downloads.cursor.com, checks its sha256 and unpacks it with bsdtar:
   git clone --depth 1 https://github.com/omacom/omarchy-pkgs ~/code/omarchy-pkgs
   cd ~/code/omarchy-pkgs/pkgbuilds/grok-bot && makepkg -si
   Show me the PKGBUILD before running makepkg. Do not use dpkg, and do not download the app from anywhere else.
3. Check that `grok-bot` is on PATH and that grok-bot.desktop exists in /usr/share/applications.
4. Add a launcher and a keybinding. If ~/.local/bin/grokbot is missing, create it as a script that runs `omarchy-launch-or-focus '^grok-bot$' 'uwsm-app -- grok-bot'`. Then add Super+Ctrl+G to open or focus it: in ~/.config/hypr/bindings.lua (Lua config, Omarchy 4.x) add
   o.bind("SUPER + CTRL + G", "Grok Bot", { launch = "grok-bot", focus = "^grok-bot$" })
   or in ~/.config/hypr/bindings.conf (classic config, Omarchy 3.x) add
   bindd = SUPER CTRL, G, Grok Bot, exec, omarchy-launch-or-focus ^grok-bot$ "uwsm-app -- grok-bot"
   First run `omarchy menu keybindings --print` (or `hyprctl binds`) and tell me if Super+Ctrl+G is already taken.
If a step needs sudo and you cannot type my password, stop and give me the exact command to run myself.
```

**Manual commands** (pick the first that works):

```bash
# 1. Omarchy's package repo (Omarchy 4.x; also in the menu: Install > AI > Grok Bot)
pacman -Si grok-bot && omarchy-pkg-add grok-bot

# 2. Omarchy's PKGBUILD: fetches the official .deb, verifies sha256, unpacks with bsdtar, installs with pacman
git clone --depth 1 https://github.com/omacom/omarchy-pkgs ~/code/omarchy-pkgs
cd ~/code/omarchy-pkgs/pkgbuilds/grok-bot && makepkg -si

# 3. AUR repack of the official .deb (community maintained; read the PKGBUILD first)
yay -S grok-bot-desktop

# 4. A .deb you already downloaded, converted with debtap (AUR)
yay -S debtap && sudo debtap -u
debtap -q grok-bot_*_amd64.deb && sudo pacman -U grok-bot-*.pkg.tar.zst
```

Then open it, sign in and register the machine with Grok Bot. Once hypr-hands is installed you also get a `grokbot` launcher (opens Grok Bot, or focuses it if it is already running) and a one-shot binding helper:

```bash
grokbot                       # open or focus Grok Bot
hypr-hands grokbot status     # installed? running? launcher and keybinding present?
hypr-hands grokbot bind       # add Super+Ctrl+G to ~/.config/hypr/bindings.lua (Lua) or bindings.conf (classic)
hypr-hands grokbot install-help
```

Without hypr-hands, add the binding yourself:

```lua
-- ~/.config/hypr/bindings.lua (Omarchy 4.x, Lua config)
o.bind("SUPER + CTRL + G", "Grok Bot", { launch = "grok-bot", focus = "^grok-bot$" })
```
```ini
# ~/.config/hypr/bindings.conf (Omarchy 3.x, classic config)
bindd = SUPER CTRL, G, Grok Bot, exec, omarchy-launch-or-focus ^grok-bot$ "uwsm-app -- grok-bot"
```
and a shell alias if you like: `echo "alias grokbot='omarchy-launch-or-focus ^grok-bot\$ \"uwsm-app -- grok-bot\"'" >> ~/.bashrc`.

`Super + Ctrl + G` is free in Omarchy 3.8.4 and 4.0.5 (`Super + Shift + Ctrl + G` is Google Messages). Pick another key with `hypr-hands grokbot bind --key "SUPER + ALT + G"`. Remove the app with the Omarchy menu (Remove > AI > Grok Bot) or `sudo pacman -Rns grok-bot`.

## Quick start

1. **Create the bot** from the Grok Bot template: https://x.ai/bot/34-oSa3xbDgnKAt8G_nq_
2. **Connect your Omarchy computer** to Grok Bot: install the Grok Bot desktop app (see [Install the Grok Bot desktop app first](#install-the-grok-bot-desktop-app-first) or [`docs/install-grok-bot.md`](docs/install-grok-bot.md)), sign in and register the machine.
3. **Ask the bot to set itself up.** It runs the installer on your machine for you (`install.sh --yes --no-packages`) and tells you the one-line `sudo pacman …` / `yay …` command for anything missing (sudo needs your terminal).

Manual install on the Omarchy machine:

```bash
git clone https://github.com/perwendelboe-lab/omarchy-ui-helper ~/code/omarchy-ui-helper && ~/code/omarchy-ui-helper/install.sh
```
`install.sh` flags: `--dry-run`, `--yes`/`--non-interactive`, `--with-cua`, `--with-ydotool`, `--no-packages`, `--no-copy`. Steps: detect Omarchy/Hyprland/Wayland → pacman packages (`grim slurp wl-clipboard tesseract tesseract-data-eng jq wtype`) → `yay -S aur/wlrctl` → optional Cua Driver → optional ydotool → copy to `~/.local/share/hypr-hands` + `hypr-hands` and `grokbot` in `~/.local/bin` → `hypr-hands check` and a Grok Bot app check. It never edits your Hyprland config; `hypr-hands grokbot bind` does that only when you run it.
Update: `git -C ~/code/omarchy-ui-helper pull && ~/code/omarchy-ui-helper/install.sh --yes --no-packages`. Remove: `./uninstall.sh` (`--ydotool`, `--cua`, `--packages`, `--dry-run`).

## Compatibility (Omarchy channels)

| | Edge / dev (tested) | Stable 4.0.x (4.0.0–4.0.6) | Omarchy 3.x / plain Hyprland `.conf` |
|---|---|---|---|
| Hyprland | 0.56.2 (Lua config) | 0.56.x (Lua config) | classic hyprlang |
| Dispatch used | `hyprctl repl` + `hl.dsp.*` | same | `hyprctl dispatch …` (auto-detected; untested live) |
| `omarchy-menu-keybindings`, `omarchy` CLI, `omarchy-menu` layer, `/usr/share/omarchy/default/agents/skills/omarchy` | ✅ | ✅ | menus differ; not covered |
| Packages (grim, wtype, tesseract, ydotool from Arch/Omarchy mirrors; wlrctl from AUR) | ✅ | ✅ | ✅ |
| Grok Bot desktop app | `grok-bot` package / Install > AI | `grok-bot` package where the repo has it, else PKGBUILD/AUR | PKGBUILD/AUR/debtap |
| `grokbot` launcher + `Super + Ctrl + G` (`hypr-hands grokbot bind`) | `bindings.lua` | `bindings.lua` | `bindings.conf` (or `hyprland.conf`) |

Force a style with `HYPR_HANDS_DISPATCH=lua|classic`; `HYPR_HANDS_DRYRUN=1` prints dispatch commands instead of running them.

Omarchy 4.0.5 and 4.0.6 (October 2026) change nothing hypr-hands depends on: same Hyprland Lua config and `hl.dsp` dispatch, same `omarchy-menu` / `omarchy-menu-keybindings` and `omarchy-menu` layer, same bundled `omarchy` skill, same packages. Its GitHub home is now `omacom/omarchy` (the old `basecamp/omarchy` URLs redirect); `update-check` and `breaking-watch` use the new one.

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

**Drag uses Cua first (v0.6.0).** When the daemon runs (with `CUA_DRIVER_RS_ENABLE_WAYLAND=1`), `hypr-hands drag X1 Y1 X2 Y2` calls Cua's desktop-scope drag (`cua-driver call drag '{"scope":"desktop",...}'`), which holds the button through `zwlr_virtual_pointer_v1` for the whole gesture: one press, interpolated motion, one release. hypr-hands converts its logical px to Cua's physical desktop frame (Cua frame ÷ logical layout, e.g. ×1.5 at scale 1.5), keeps the lock check, the verified move to the start and the target guard, checks the end cursor position, and prints `"backend":"cua-driver-vptr"`. `hypr-hands check` reports `drag_backend`. With more than one monitor it uses Cua only when forced with `HYPR_HANDS_DRAG_BACKEND=cua`, because that frame mapping has not been tested on multi-monitor setups yet. Drags with modifier keys held are refused.

## Optional: ydotool (fallback only) — default off

Only needed as a fallback: `drag` uses Cua Driver when its daemon runs (see above).
- **Enables:** `drag` when Cua Driver is not available (button hold; wlrctl can only click), and click/scroll when wlrctl is missing.
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

## Window layouts: snapshot / restore

`hypr-hands windows snapshot [FILE]` saves every window's address, class, workspace, floating, fullscreen, position and size to `$XDG_STATE_HOME/hypr-hands/layout-*.json` (read-only). `hypr-hands windows restore [FILE]` (default: newest) puts back workspaces, floating/tiled state, fullscreen, and position/size of floating windows; tiled geometry follows the layout (best effort). The skills snapshot before rearranging and offer restore afterwards.

## Update checks + weekly routine

- `hypr-hands update-check [--json] [--apply]` — cua-driver, Omarchy (incl. dev channel), Hyprland, wlrctl, ydotool, the Grok Bot desktop app and hypr-hands itself (installed copy or clone vs GitHub `main`); flags major bumps. `--apply` only runs the sudo-free `cua-driver update --apply`.
- `hypr-hands breaking-watch [--json]` — release notes (cua-driver, Hyprland) and Omarchy commits since your installed version, scanned for breaking/Lua/dispatch/Wayland/uinput keywords.
- Add a weekly Grok Bot routine with the prompt in [`docs/routine-prompt.md`](docs/routine-prompt.md).

## Safety

- Everything runs on *your* machine only through the bot's Shell tool with your machineId; the bot asks before taking over your pointer/keyboard.
- **Target guard:** `HYPR_HANDS_REQUIRE_CLASS=<prefix>` — click/scroll/drag refuse unless the focused window and the window under the cursor match; type/key require the focused window (exit 8).
- **Locked screen:** input refused while `hyprlock` runs (exit 3). **Verified pointer:** ±2 px `cursorpos` check (exit 4). **Secrets:** `type` refuses secret-looking text (exit 6).
- **uinput opt-in:** ydotool only with `HYPR_HANDS_ALLOW_UINPUT=1`. The bot never runs sudo; installs needing root are handed to you.
- Backend order: Cua Driver (accessibility) → Lua cursor move + `wlrctl` → `hypruse` → `ydotool` (opt-in). Drag: Cua Driver desktop drag (virtual pointer) → `ydotool` (opt-in).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `hyprctl dispatch movecursor 100 100` → Lua `')' expected` | Lua-config Hyprland routes `dispatch` through `hl.dispatch`. Use `hyprctl repl "hl.dispatch(hl.dsp.cursor.move({ x = 100, y = 100 })); return 'ok'"` (named fields). Also `hl.dsp.focus({ window = 'address:0x…' })`, `hl.dsp.window.move({ workspace = '3', follow = false })`, `hl.dsp.window.fullscreen()`, `hl.dsp.window.close()`, `hl.dsp.window.float({ action = 'toggle' })`, `hl.dsp.window.resize({ x, y, relative })`, `hl.dsp.window.swap({ direction = 'l' })`, `hl.dsp.layout('togglesplit')`. |
| `/dev/uinput` not writable after setup | New login needed for the `input` group; check `id -nG`. |
| ydotool "failed to connect socket" | Arch user unit uses `$XDG_RUNTIME_DIR/.ydotool_socket`; scripts auto-detect, else `export YDOTOOL_SOCKET=…`. |
| `yay -S wlrctl` says "nothing to do" | Use `yay -S aur/wlrctl`. |
| `grokbot` exit 10 "Grok Bot desktop app not found" | Install the app first: `hypr-hands grokbot install-help`. |
| `Super + Ctrl + G` does nothing | `hypr-hands grokbot status` → `keybinding.installed`; check `hyprctl binds` for a clash, then `hyprctl reload`. |
| `hypr-hands: command not found` | Add `~/.local/bin` to PATH or call `~/.local/share/hypr-hands/bin/hypr-hands`. |
| `click` exit 5 "no click backend" | Install wlrctl or opt in to ydotool. |
| `drag` exit 5 "no drag backend" | Start the Cua Driver daemon with `CUA_DRIVER_RS_ENABLE_WAYLAND=1` (`systemctl --user start cua-driver.service`), or opt in to ydotool. The error says why Cua was skipped (not installed, daemon down, multi-monitor, frame mismatch). |
| `drag` exit 11 "cua-driver drag failed" | Cua failed after it may have started the gesture; check the screen before retrying. `cua-driver doctor`. |
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
| drag via Cua Driver 0.37.0 desktop drag (v0.6.0, `cua-driver-vptr`) | ⚠️ virtual test only: headless sway 1.12 (Hyprland 0.56.2 needs a GPU the test box lacks), GTK4 GestureDrag + `wev`: 1 press, 20 held motions, 1 release at the target; scale 1 and 1.5 ✅. Not yet tested on real Omarchy/Hyprland |
| type / key incl. chords | ✅ (raw byte log) |
| target guard, secret refusal | ✅ · lock refusal ⚠️ not exercised live |
| shot full, ocr-find, clip | ✅ · shot region/select/window ⚠️ untested |
| windows list/focus/move/fullscreen/close | ✅ |
| windows float/resize (exact+relative)/moveto/center/swap/movedir/focusdir/pseudo/split/snapshot/restore (v0.4.0) | ✅ Lua live · classic dry-run only |
| Omarchy keybindings menu flow | ✅ |
| install.sh (dry-run + real `--yes --no-packages`), update-check, breaking-watch | ✅ · fresh-machine install with packages ⚠️ untested |
| hypruse backend | ⚠️ untested |

## Privacy

Runtime output stays out of the repo: screenshots/OCR in `$XDG_RUNTIME_DIR/hypr-hands`, caches in `$XDG_CACHE_HOME/hypr-hands`. Before committing, run `scripts/privacy-check.sh` (staged files) or `--all`, or install it as a hook: `ln -sf ../../scripts/privacy-check.sh .git/hooks/pre-commit`. Put personal patterns (your email, hostname, machine IDs) in `~/.config/hypr-hands/privacy-patterns`, not in the repo.

## Credits & third-party

hypr-hands is an independent project, not affiliated with or endorsed by any of these:

- [Omarchy](https://github.com/omacom/omarchy) (MIT, © David Heinemeier Hansson): `skills/omarchy` is copied and adapted from Omarchy's bundled agent skill; their notice is in `skills/omarchy/LICENSE`.
- [Cua Driver](https://github.com/trycua/cua) (MIT, © Cua AI, Inc.): optional. It is downloaded from Cua's official installer, not bundled.
- [Hyprland](https://github.com/hyprwm/Hyprland) (BSD-3-Clause).
- Tools installed as system packages, not redistributed: [wlrctl](https://git.sr.ht/~brocellous/wlrctl) (MIT), [wtype](https://github.com/atx/wtype) (MIT), [grim](https://git.sr.ht/~emersion/grim) (MIT), [tesseract](https://github.com/tesseract-ocr/tesseract) (Apache-2.0), [ydotool](https://github.com/ReimuNotMoe/ydotool) (AGPL-3.0, opt-in).

Details: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

## License

MIT © 2026 PWN, except `skills/omarchy/` (MIT, © David Heinemeier Hansson; see THIRD_PARTY_NOTICES.md).
