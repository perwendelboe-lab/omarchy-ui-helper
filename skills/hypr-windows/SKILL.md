---
name: hypr-windows
description: List, focus, move-to-workspace, fullscreen, close and wait for windows on the user's Omarchy/Hyprland computer via hyprctl Lua dispatch.
---
# Windows (remote)
Run via Shell with the user's Omarchy `machineId`.

```bash
hypr-hands windows list                 # JSON: address, class, title, workspace, geometry
hypr-hands windows focus 0xADDR
hypr-hands windows move 0xADDR WS       # hl.dsp.window.move({workspace=WS, follow=false})
hypr-hands windows fullscreen [0xADDR]  # toggle; verify .fullscreen 0/2 in `hyprctl clients -j`
hypr-hands windows close 0xADDR         # only windows you opened
hypr-hands wait-window CLASS [timeout]  # after launching an app
```
Scripts auto-detect the dispatch style. Raw forms:
- Lua config (Omarchy 4.x stable/edge): `hyprctl repl "hl.dispatch(hl.dsp.focus({ window = 'address:0x…' })); return 'ok'"`, `hl.dsp.window.move({ workspace = 'N', follow = false })`, `hl.dsp.window.fullscreen()`, `hl.dsp.window.close()`.
- Classic `.conf` (Omarchy 3.x, plain Hyprland): `hyprctl dispatch focuswindow address:0x…`, `movetoworkspacesilent N`, `fullscreen 0`, `killactive`.
 Focusing a window on another workspace switches to it. Ask before rearranging the user's windows; afterwards refocus what they had.
