---
name: omarchy-menus
description: Drive Omarchy menus (keybindings menu, main menu) by keyboard on the user's Omarchy computer, e.g. to trigger an action by name.
---
# Omarchy menus (remote)
Run via Shell with the user's Omarchy `machineId`. Menus are keyboard-filtered lists — no pointer needed.

1. Focus the intended target window first (menu actions apply to it), and set `HYPR_HANDS_REQUIRE_CLASS` to its class.
2. Open: `setsid omarchy-menu-keybindings >/dev/null 2>&1 &` (or `omarchy-menu` for the main menu).
3. Confirm the layer is up: `hyprctl layers -j | jq '[.[].levels[][]|.namespace]'` contains `omarchy-menu`. The menu takes keyboard focus while `activewindow` still reports the underlying window.
4. `hypr-hands type 'Full screen'`, check with `hypr-hands shot` / `ocr-find`, then `hypr-hands key Return`.
5. Verify the effect (e.g. `hyprctl clients -j` fullscreen). Cancel with `hypr-hands key Escape` only while the menu layer is present.
Works the same on Omarchy stable (4.0.x) and edge: `omarchy-menu-keybindings`, `omarchy-menu` and the `omarchy-menu` layer namespace exist in both. Never edit `/usr/share/omarchy`.
