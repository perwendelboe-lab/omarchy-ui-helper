# Install the Grok Bot desktop app on Omarchy

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

# Not offered on purpose: AUR repacks (grok-bot-desktop) and debtap. The AUR has had malware incidents and its
# packages run arbitrary build scripts, so hypr-hands never suggests or installs from it.
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

After that, continue with the [Quick start](../README.md#quick-start) to install hypr-hands.
