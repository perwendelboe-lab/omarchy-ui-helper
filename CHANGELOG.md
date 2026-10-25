# Changelog

All notable changes to hypr-hands. Versions follow SemVer.

## 0.6.1 — 2026-10-25
### Changed
- `update-check` now compares the installed Grok Bot desktop app with the official Linux update feed, not only `pacman -Si`. The app ships a new version almost daily and pacman's package list lags, so a stale app was easy to miss. It reports `update-available` when the feed is newer and keeps the pacman/AUR version in `source`; if the feed can't be reached it falls back to the old behaviour.
- Compatibility notes cover Omarchy 4.0.6 (update and lock-screen fixes only; nothing hypr-hands uses changed). Omarchy 4.5 is in release candidate and is reported to translate menus, so match menu entries by what is on screen.

## 0.6.0 — 2026-10-20
### Changed
- `drag` is Cua-first: when `cua-driver` is installed and its daemon is running (started with `CUA_DRIVER_RS_ENABLE_WAYLAND=1`), it calls Cua Driver's desktop-scope drag, which holds the button over `zwlr_virtual_pointer_v1` for the whole gesture (one press, interpolated motion, one release) and prints `"backend":"cua-driver-vptr"`. Logical px are converted to Cua's physical desktop frame (Cua `get_desktop_state` size ÷ logical monitor layout; refused if the two axes disagree). It keeps the lock check, the verified move to the start and the target guard, and checks the end cursor position (exit 4). ydotool stays the opt-in fallback (`HYPR_HANDS_ALLOW_UINPUT=1`), used when Cua is unavailable or refuses before sending input; a Cua failure after that is exit 11 with no retry.
- With more than one monitor, Cua drag is used only with `HYPR_HANDS_DRAG_BACKEND=cua` (untested frame mapping). `HYPR_HANDS_DRAG_BACKEND=auto|cua|ydotool`, `HYPR_HANDS_DRAG_MS` (default 500), steps default 20.
- Drags with modifier keys are refused explicitly (non-integer arguments such as `--shift` → exit 2).
- README: ydotool is only needed as a fallback; tested-matrix row for the virtual Cua drag test. Skills `hypr-pointer`, `hypr-computer-use`, `cua-driver-local-computer-use` describe the Cua-first drag and Cua's physical desktop frame.
### Added
- `check` reports `drag_backend` (`cua-driver-vptr` | `ydotool` | `none`).
- `lib.sh`: `cua_bin`, `cua_ready`, `layout_box`, `cua_desktop_size`, `drag_backend`.
### Tested
- Virtual only: Hyprland 0.56.2 (Arch) could not start on the GPU-less test box (Aquamarine: no DRM, "no allocator available"), so headless sway 1.12 (pixman) with cua-driver 0.37.0 was used. A GTK4 GestureDrag client and `wev` logged one press, 20 held motions and one release at the target, at scale 1 and 1.5. `check`, `move`, `click` (wlrctl) and `drag` ran through a test-only `hyprctl` shim. Needs a confirming run on real Omarchy.

## 0.5.0 — 2026-10-19
### Added
- `hypr-hands grokbot [open|status|bind|install-help]` and a `grokbot` launcher in `~/.local/bin` (symlinked by `install.sh`, removed by `uninstall.sh`): open or focus the Grok Bot desktop app (Lua `hl.dsp.focus` or classic `focuswindow`, launch through `uwsm-app`), report install/run/keybinding state as JSON, print install methods.
- `grokbot bind [--key …] [--dry-run]`: idempotently adds `Super + Ctrl + G` to `~/.config/hypr/bindings.lua` (Lua config) or `bindings.conf`/`hyprland.conf` (classic), keeps a `.hypr-hands.bak` copy and warns when the combo is already bound.
- README section and `docs/install-grok-bot.md`: the Grok Bot desktop app is not preinstalled on some Omarchy versions; ready-to-paste prompt for the Omarchy default agent, manual commands (Omarchy repo `grok-bot`, Omarchy's PKGBUILD from the official .deb, AUR `grok-bot-desktop`, debtap), keybinding and alias.
- `check` lists `grok-bot`/`grokbot`; `update-check` reports the Grok Bot app package; `install.sh` says whether the app is installed.
### Changed
- Omarchy URLs moved to `github.com/omacom/omarchy` (Omarchy 4.0.5 renamed its GitHub home); `update-check` and `breaking-watch` use it.
- Checked against Omarchy 4.0.5: no changes to the Lua config / `hl.dsp` API, `omarchy-menu`, `omarchy-menu-keybindings`, the `omarchy-menu` layer, `uwsm-app`, the bundled `omarchy` skill or the packages hypr-hands uses. Skills and README compatibility notes now say 4.0.0–4.0.5.
### Fixed
- `update-check` / `breaking-watch` no longer exit early when a version string is empty (`semver` under `pipefail`).
- `breaking-watch` passes release notes to jq on stdin instead of `--argjson`, which hit "Argument list too long" when many releases were new.

## 0.4.0 — 2026-10-15
### Added
- `windows float [ADDR] [toggle|on|off]`, `resize [ADDR] W H` (exact) / `+DX +DY` (relative), `moveto [ADDR] X Y`, `center [ADDR]`, `swap [ADDR] l|r|u|d`, `movedir [ADDR] l|r|u|d`, `focusdir l|r|u|d`, `pseudo [ADDR]`, `split [ADDR]`; Lua (`hl.dsp.window.float/resize/move/swap/center/pseudo`, `hl.dsp.focus({direction})`, `hl.dsp.layout('togglesplit')`) and classic (`togglefloating/setfloating/settiled`, `resizewindowpixel`, `movewindowpixel`, `swapwindow`, `movewindow`, `movefocus`, `centerwindow`, `pseudo`, `togglesplit`) forms in `lib.sh`.
- `windows snapshot [FILE]` / `windows restore [FILE]`: layout undo saved in `$XDG_STATE_HOME/hypr-hands/layout-*.json`.
### Changed
- `hypr-windows` and `hypr-computer-use` skills: snapshot before rearranging, offer restore afterwards.

## 0.3.3 — 2026-10-15
### Added
- `THIRD_PARTY_NOTICES.md` and `skills/omarchy/LICENSE` with Omarchy's MIT notice (the omarchy skill is copied/adapted from Omarchy).
- README "Credits & third-party" section: Omarchy, Cua, Hyprland, wlrctl, wtype, grim, tesseract, ydotool and their licenses; unaffiliated; Cua is fetched from its official installer, not bundled.

## 0.3.2 — 2026-10-15
### Added
- `.gitignore` for secrets (`.env*`, keys), logs, screenshots/OCR/runtime output, state/cache dirs, OS and editor files.
- `scripts/privacy-check.sh`: pre-commit grep for emails, home paths, MAC/IP addresses, UUIDs, tokens and private keys (extra local patterns from `~/.config/hypr-hands/privacy-patterns`).

## 0.3.1 — 2026-10-15
### Added
- Dispatch backend detection in `lib.sh`: Lua (`hyprctl repl` + `hl.dsp.*`, Omarchy 4.x stable/edge) or classic `hyprctl dispatch` (hyprland.conf setups). Override with `HYPR_HANDS_DISPATCH`, preview with `HYPR_HANDS_DRYRUN=1`. Used by move/drag/windows; `check` reports `dispatch`.
- Clear JSON error (exit 9) when a dispatch fails.
- Compatibility notes for Omarchy stable vs edge in README and skills.

## 0.3.0 — 2026-10-15
### Changed
- Retargeted to **Grok Bot only** (project name: Omarchy UI Helper). Skills rewritten for a bot that drives the user's Omarchy computer remotely (Shell + machineId).
- Installs to `~/.local/share/hypr-hands` (rsync copy) with a `hypr-hands` CLI symlinked into `~/.local/bin`; no Cursor plugin folder any more. `uninstall.sh` matches (and removes the pre-0.3 `~/.cursor/plugins/local/hypr-hands` copy).
- `update-check.sh` compares the installed copy or a local clone against GitHub `main`; works from the install dir.
### Removed
- `.cursor-plugin/` manifest and Cursor marketplace instructions (the Agent Plugins `plugin.json` stays).

## 0.2.0 — 2026-10-15
### Added
- Bundled skills `cua-driver-local-computer-use` (genericized, with hypr-hands fallback and Hyprland Lua dispatch notes) and `omarchy` (+ topic guides, from Omarchy's own agent skill).
- `install.sh` guided installer (`--yes`, `--non-interactive`, `--dry-run`, `--with-cua`, `--with-ydotool`, `--no-packages`, `--no-copy`) and `uninstall.sh` (`--ydotool`, `--cua`, `--packages`, `--dry-run`).
- `scripts/update-check.sh` (cua-driver, Omarchy incl. dev channel, Hyprland, wlrctl, ydotool, hypr-hands; JSON + summary; `--apply` for the sudo-free cua-driver update).
- `scripts/breaking-watch.sh` (release notes / commits since installed version, keyword scan) and `docs/routine-prompt.md`.
- `HYPR_HANDS_REQUIRE_CLASS` target-window guard for click/scroll/type/key/drag.
- `drag.sh` via Lua absolute moves + ydotool button down/up; ydotoold socket auto-detection.
- `assets/logo.png`, rewritten README.
### Changed
- Plugin is now copied into `~/.cursor/plugins/local/hypr-hands` (Cursor skips symlinks pointing outside that folder).
- `scroll.sh`: wlrctl argument order is `<dy> <dx>`; one step = 15 units (one wheel notch).

## 0.1.0 — 2026-10-15
### Added
- Initial plugin: manifests, skills (hypr-computer-use, hypr-pointer, hypr-windows, omarchy-menus, screen-read), scripts (check, setup, geom, move, click, scroll, drag, type, key, shot, ocr-find, clip, windows, wait-window, describe).
- Cursor movement through `hyprctl repl` + `hl.dsp.cursor.move` (classic `dispatch movecursor` fails on Lua-config Hyprland).
