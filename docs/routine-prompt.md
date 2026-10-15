# Scheduled routine: weekly hypr-hands update + breaking-change check

Suggested schedule: weekly, Monday 09:00 local time. Target: the Omarchy computer.

## Prompt (paste as the routine's instruction)

```
Weekly hypr-hands health check on my Omarchy computer. Read-only: do not install,
update, restart services or send any input.

1. On the Omarchy machine (Shell with its machineId), run:
     ~/code/hypr-hands/scripts/check.sh
     ~/code/hypr-hands/scripts/update-check.sh --json
     ~/code/hypr-hands/scripts/breaking-watch.sh --json
   (If the repo lives elsewhere, use the installed copy under
    ~/.cursor/plugins/local/hypr-hands/scripts/.)
2. Summarise for me:
   - anything not "up-to-date" in update-check (installed -> latest), flag major_bump items first;
   - breaking-watch keyword hits that could affect hypr-hands: Hyprland Lua dispatch / hyprctl
     syntax (hl.dsp.*, cursor.move, cursorpos), Wayland virtual-pointer / wlr protocols,
     uinput/ydotool, cua-driver Wayland/AT-SPI behaviour, Omarchy menu/keybinding changes;
   - check.sh problems (click_backend none, cua-driver service not active, locked=true).
3. For each update, give the exact command I would run (cua-driver: `cua-driver update --apply`
   then `systemctl --user restart cua-driver.service`; Omarchy/Hyprland: `omarchy update`;
   AUR: `yay -S aur/<pkg>`). Do not run them.
4. If nothing changed and no hits: reply with one line "hypr-hands: all current, no breaking notes".
```
