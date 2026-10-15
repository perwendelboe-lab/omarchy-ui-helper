---
name: omarchy-menus
description: Drive Omarchy menus and launchers (walker-based) by keyboard, e.g. look up keybindings or run Omarchy actions.
---
# Omarchy menus
Omarchy menus are keyboard-filtered lists — no pointer needed.
- Keybindings: run `omarchy-menu-keybindings` (or Super+K via `scripts/key.sh super+k`), then `scripts/type.sh "filter text"`, then `scripts/key.sh Return`.
- Main menu: `omarchy-menu` (Super+Alt+Space), same filter-then-Return pattern.
- Close with `scripts/key.sh Escape`.
Verify with `describe.sh` / `shot.sh` that the menu opened before typing. Don't edit `/usr/share/omarchy`.


Tested: launched `omarchy-menu-keybindings` (layer namespace `omarchy-menu`, check with `hyprctl layers -j`), `type.sh 'Full screen'`, `key.sh Return` → focused window went fullscreen. The menu layer takes keyboard focus while `activewindow` still reports the underlying window.
