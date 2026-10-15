# Changelog

All notable changes to hypr-hands. Versions follow SemVer.

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
