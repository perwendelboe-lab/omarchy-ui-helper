---
name: hypr-windows
description: List, focus, move, float/tile, resize, position, swap, center, split, snapshot/restore and close windows on the user's Omarchy/Hyprland computer via hyprctl Lua dispatch (classic dispatch auto-detected).
---
# Windows (remote)
Run via Shell with the user's Omarchy `machineId`. `ADDR` is optional where shown in brackets (default: the active window).

```bash
hypr-hands windows list                     # JSON: address, class, title, workspace, geometry, floating, fullscreen
hypr-hands windows snapshot [FILE]          # save every window -> $XDG_STATE_HOME/hypr-hands/layout-*.json (read-only)
hypr-hands windows restore [FILE]           # put back workspaces, floating, fullscreen, floating pos/size (default: newest snapshot)
hypr-hands windows focus 0xADDR
hypr-hands windows move 0xADDR WS           # to workspace, silently
hypr-hands windows fullscreen [0xADDR]      # toggle; verify .fullscreen 0/2
hypr-hands windows float [0xADDR] [toggle|on|off]
hypr-hands windows resize [0xADDR] W H      # exact px (floating windows)
hypr-hands windows resize [0xADDR] +DX -DY  # relative (tiled windows; any sign makes it relative)
hypr-hands windows moveto [0xADDR] X Y      # exact position, floating windows
hypr-hands windows center [0xADDR]          # floating windows
hypr-hands windows swap [0xADDR] l|r|u|d    # swap with the neighbour
hypr-hands windows movedir [0xADDR] l|r|u|d # move within the layout
hypr-hands windows focusdir l|r|u|d
hypr-hands windows pseudo [0xADDR]          # toggle pseudotile
hypr-hands windows split [0xADDR]           # dwindle togglesplit
hypr-hands windows close 0xADDR             # only windows you opened
hypr-hands wait-window CLASS [timeout]      # after launching an app
```

## Snapshot first, restore offered after
Before any rearranging (float, resize, moveto, center, swap, movedir, move, pseudo, split, fullscreen), run `hypr-hands windows snapshot` and keep the file path it prints. When done, tell the user and offer `hypr-hands windows restore FILE` as an undo. Restore is best effort: tiled windows get their workspace and tiled state back, but exact tiled positions follow the layout; closed windows are listed under `missing`.

## Dispatch forms
Scripts auto-detect the style (`HYPR_HANDS_DISPATCH=lua|classic`; `HYPR_HANDS_DRYRUN=1` prints commands).
- Lua config (Omarchy 4.x): `hyprctl repl "hl.dispatch(hl.dsp.….); return 'ok'"` with `hl.dsp.focus({ window = 'address:0x…' })`, `hl.dsp.focus({ direction = 'l' })`, `hl.dsp.window.move({ workspace = 'N', follow = false })`, `hl.dsp.window.float({ action = 'toggle'|'on'|'off', window = … })`, `hl.dsp.window.resize({ x = W, y = H, relative = false|true, window = … })`, `hl.dsp.window.move({ x = X, y = Y, window = … })`, `hl.dsp.window.move({ direction = 'l' })`, `hl.dsp.window.swap({ direction = 'l' })`, `hl.dsp.window.center({ window = … })`, `hl.dsp.window.pseudo()`, `hl.dsp.layout('togglesplit')`, `hl.dsp.window.fullscreen()`, `hl.dsp.window.close()`.
- Classic `.conf` (Omarchy 3.x): `focuswindow address:0x…`, `movefocus l`, `movetoworkspacesilent N`, `togglefloating|setfloating|settiled address:0x…`, `resizewindowpixel exact W H,address:0x…` (or `DX DY,…`), `movewindowpixel exact X Y,address:0x…`, `movewindow l`, `swapwindow l`, `centerwindow`, `pseudo`, `togglesplit`, `fullscreen 0`, `killactive`.

Focusing a window on another workspace switches to it. Ask before rearranging the user's windows; afterwards refocus what they had.
