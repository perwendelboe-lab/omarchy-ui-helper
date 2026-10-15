---
name: hypr-windows
description: List, focus, move-to-workspace, fullscreen and wait for Hyprland windows via hyprctl Lua dispatch.
---
# Windows
- `scripts/windows.sh list` — JSON clients (address, class, title, workspace, geometry).
- `scripts/windows.sh focus 0xADDR`
- `scripts/windows.sh move 0xADDR WS` — `hl.dsp.window.move({workspace=WS, follow=false})`.
- `scripts/windows.sh fullscreen [0xADDR]`
- `scripts/windows.sh close 0xADDR` — only for windows you opened.
- `scripts/wait-window.sh CLASS [timeout]` — after launching an app.
Raw: `hyprctl repl "hl.dispatch(hl.dsp.focus({ window = 'address:0x…' })); return 'ok'"`.
Ask before rearranging the user's existing windows.


Tested: list, focus, move to workspace 9 (follow=false) and back, fullscreen 0→2→0, close. Note: focusing a window on another workspace switches to that workspace.
