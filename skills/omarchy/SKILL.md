---
name: omarchy
description: >-
  REQUIRED for end-user customization of Linux desktop, window manager, or
  system config. Use when editing ~/.config/hypr/, ~/.config/omarchy/,
  ~/.config/alacritty/, ~/.config/foot/, ~/.config/kitty/, or
  ~/.config/ghostty/. Triggers: Hyprland, window rules, animations, keybindings,
  monitors, gaps, borders, blur, opacity, omarchy-shell, bar, terminal config,
  themes, background, night light, idle, lock screen, screenshots, reminders,
  layer rules, workspace settings, display config, and user-facing omarchy
  commands. Excludes Omarchy source development through omarchy dev link
  workflows.
---
# Omarchy Skill

Manage [Omarchy](https://omarchy.org/) Linux systems - a beautiful, fun, agentic Arch Linux distribution with Hyprland.

This skill is for end-user customization on installed systems.
It is not for contributing to Omarchy source code.

## When This Skill MUST Be Used

**ALWAYS invoke this skill for end-user requests involving ANY of these:**

- Editing ANY file in `~/.config/hypr/` (window rules, animations, keybindings, monitors, etc.)
- Editing `~/.config/omarchy/shell.json` (status bar layout, widgets)
- Editing terminal configs (alacritty, foot, kitty, ghostty)
- Editing ANY file in `~/.config/omarchy/`
- Window behavior, animations, opacity, blur, gaps, borders
- Layer rules, workspace settings, display/monitor configuration
- Themes, backgrounds, fonts, appearance changes
- User-facing `omarchy` commands (`omarchy theme ...`, `omarchy refresh ...`, `omarchy restart ...`, etc.)
- Screenshots, screen recording, reminders, night light, idle behavior, lock screen

**If you're about to edit a config file in ~/.config/ on this system, STOP and use this skill first.**

**Do NOT use this skill for Omarchy development tasks** (editing the Omarchy source tree, creating migrations, or running `omarchy dev ...` workflows).

## Topic Guides

Deeper instructions for common areas live next to this file. Read the matching guide before starting:

- [`hyprland.md`](hyprland.md) - keybindings, monitors, window rules, and other Hyprland config
- [`plugins.md`](plugins.md) - the Omarchy shell: bar layout, widgets, plugins, idle behavior
- [`theming.md`](theming.md) - themes, backgrounds, and fonts
- [`hooks.md`](hooks.md) - automation hooks that run on system events
- [`capture.md`](capture.md) - screenshots, screen recordings, OCR text capture, and file sharing
- [`contributing.md`](contributing.md) - reporting Omarchy bugs and submitting fixes upstream

## Critical Safety Rules

For privileged commands, follow the Privilege Escalation rules below: `sudo` when a terminal is available for the password prompt, `pkexec` when it is not. Do not wrap commands that already manage privilege elevation themselves.

**For end-user customization tasks, NEVER modify anything in `/usr/share/omarchy/`** - but READING is safe and encouraged.

This directory is owned by the omarchy package. Any local changes will be overwritten on the next `omarchy update`.

```
/usr/share/omarchy/     # READ-ONLY - NEVER EDIT (reading is OK)
├── bin/                    # Command source (packaged binaries are on PATH)
├── config/                 # Default config templates
├── themes/                 # Stock themes
├── default/                # System defaults
├── shell/                  # Omarchy shell source and defaults
├── migrations/             # Update migrations
└── install/                # Installation scripts
```

**Reading `/usr/share/omarchy/` is SAFE and useful** - do it freely to understand commands, defaults, and stock themes.

**Always use these safe locations instead:**
- `~/.config/` - User configuration (safe to edit)
- `~/.config/omarchy/themes/<custom-name>/` - Custom themes
- `~/.config/omarchy/hooks/` - Custom automation hooks

## Privilege Escalation

For an interactive script or command run in a visible terminal, use `sudo` for privileged work. Omarchy may grant passwordless `sudo` access to particular commands, and the terminal is the appropriate place to request a password when one is needed.

Use `pkexec` only when the caller cannot interact with a terminal or cannot enter a password there, such as a command launched by an agent or a graphical background process. Do not replace `sudo` with `pkexec` merely because a command changes system state.

## System Architecture

Omarchy is built on:

| Component | Purpose | Config Location |
|-----------|---------|-----------------|
| **Arch Linux** | Base OS | `/etc/`, `~/.config/` |
| **Hyprland** | Wayland compositor/WM | `~/.config/hypr/` |
| **Omarchy shell** | Status bar + notifications (Quickshell) | `~/.config/omarchy/shell.json` |
| **Launcher/menus** | Quickshell menu | `~/.config/omarchy/extensions/omarchy-menu.jsonc` |
| **Alacritty/Foot/Kitty/Ghostty** | Terminals | `~/.config/<terminal>/` |
| **Omarchy OSD** | On-screen display | Quickshell plugin |

## Command Discovery

Omarchy ships a single `omarchy` CLI that dispatches to all `omarchy-*` binaries via `omarchy <group> <action>`. Always prefer this form.

```bash
omarchy commands
omarchy theme --help
omarchy refresh --help
omarchy restart --help
omarchy theme set --help
omarchy commands --json
cat $(which omarchy-theme-set)
```

### Command Groups

| Group | Purpose | Example |
|-------|---------|---------|
| `omarchy refresh` | Reset config to defaults (backs up first) | `omarchy refresh shell` |
| `omarchy restart` | Restart a service/app | `omarchy restart shell` |
| `omarchy toggle` | Toggle feature on/off | `omarchy toggle nightlight` |
| `omarchy theme` | Theme management | `omarchy theme set <name>` |
| `omarchy bar` | Bar layout and widgets | `omarchy bar move omarchy.clock --section right` |
| `omarchy plugin` | Manage/clone shell plugins | `omarchy plugin clone omarchy.clock` |
| `omarchy hook` | Install automation hooks | `omarchy hook install theme-set <script>` |
| `omarchy install` | Install optional software / packages | `omarchy install docker dbs` |
| `omarchy launch` | Launch apps | `omarchy launch browser` |
| `omarchy capture` | Screenshots and recordings | `omarchy capture screenshot` |
| `omarchy reminder` | Desktop notification reminders | `omarchy reminder 15 "Pickup Jack"` |
| `omarchy pkg` | Package management | `omarchy pkg add <pkg>` |
| `omarchy setup` | Interactive setup wizards | `omarchy setup security fingerprint` |
| `omarchy update` | System updates | `omarchy update` |

## Configuration Locations

Hyprland config lives in `~/.config/hypr/` — see [`hyprland.md`](hyprland.md).
The Omarchy shell is configured in `~/.config/omarchy/shell.json` — see [`plugins.md`](plugins.md).

### Terminals

```
~/.config/alacritty/alacritty.toml
~/.config/foot/foot.ini
~/.config/kitty/kitty.conf
~/.config/ghostty/config
```

**Command:** `omarchy restart terminal`

### Other Configs

| App | Location |
|-----|----------|
| btop | `~/.config/btop/btop.conf` |
| fastfetch | `/etc/fastfetch/config.jsonc` default; `~/.config/fastfetch/config.jsonc` user override |
| lazygit | `~/.config/lazygit/config.yml` |
| starship | `~/.config/starship.toml` |
| git | `~/.config/git/config` |

## Safe Customization Patterns

### Edit User Config Directly

```bash
# 1. Read current config
cat ~/.config/hypr/bindings.lua

# 2. Backup before changes
cp ~/.config/hypr/bindings.lua ~/.config/hypr/bindings.lua.bak.$(date +%s)

# 3. Make changes

# 4. Apply
# - Hyprland: validate with `hyprctl reload` and `hyprctl configerrors`
# - Omarchy shell: shell.json and ~/.config/omarchy/plugins/ hot-reload on save
# - Terminals: `omarchy restart terminal`
```

### Reset to Defaults -- ALWAYS SEEK USER CONFIRMATION BEFORE RUNNING

```bash
omarchy refresh shell
omarchy refresh hyprland
```

## System Commands

```bash
omarchy update
omarchy version
omarchy debug --no-sudo --print   # ALWAYS use these flags
omarchy system lock
omarchy system shutdown
omarchy system reboot
```

**IMPORTANT:** Always run `omarchy debug` with `--no-sudo --print` to avoid interactive sudo prompts.

## Troubleshooting

```bash
omarchy debug --no-sudo --print
omarchy refresh <app>
omarchy refresh config <config-file>   # path relative to ~/.config/
omarchy reinstall   # nuclear option
```

## Decision Framework

1. **Stock omarchy command?** Use it directly
2. **Config edit?** Edit in `~/.config/`, never `/usr/share/omarchy/`
3. **Theme customization?** Follow [`theming.md`](theming.md)
4. **Automation?** Follow [`hooks.md`](hooks.md)
5. **Package install?** `omarchy pkg add <pkgs...>` (or `omarchy pkg aur add` for AUR-only)
6. **Built-in shell/plugin code?** Follow [`plugins.md`](plugins.md); clone with `omarchy plugin clone`
7. **Unsure?** Run `omarchy commands` or `omarchy <group> --help`

### Reminder Requests

```bash
omarchy reminder 15 "Pickup Jack"
omarchy reminder show
omarchy reminder clear
```

## Out of Scope

- Editing files in `/usr/share/omarchy/`
- Creating or editing migrations
- Running `omarchy dev ...` commands

## Example Requests

- "Change my theme to catppuccin" -> `omarchy theme set catppuccin`
- "Add a keybinding for Super+E to open file manager" -> Check bindings, then `o.rebind` or `o.bind` in `~/.config/hypr/bindings.lua`
- "Configure my external monitor" -> Edit `~/.config/hypr/monitors.lua`
- "Make the window gaps smaller" -> Edit `~/.config/hypr/looknfeel.lua`
- "Turn on night light" -> `omarchy toggle nightlight`
- "Set a reminder in 15 minutes" -> `omarchy reminder 15 "..."`
- "Customize catppuccin colors" -> Overlay in `~/.config/omarchy/themes/catppuccin/` (see theming.md)
- "Lock after ten minutes" -> Set `idle.lock` to `600` in `~/.config/omarchy/shell.json`
- "Reset shell/bar to defaults" -> `omarchy refresh shell` (confirm first)

---
_Bundled in hypr-hands from Omarchy's own agent skill (`/usr/share/omarchy/default/agents/skills/omarchy`, Omarchy is MIT-licensed). On an Omarchy machine prefer the installed copy, which tracks your Omarchy version._
