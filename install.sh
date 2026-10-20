#!/usr/bin/env bash
set -euo pipefail
# Omarchy UI Helper (hypr-hands) guided installer.
#   ./install.sh                interactive (asks before each step)
#   ./install.sh --yes          accept defaults without asking (optional steps stay OFF
#                               unless --with-cua / --with-ydotool are given)
#   ./install.sh --non-interactive   same as --yes
#   ./install.sh --dry-run      print every command, change nothing
#   --with-cua  --with-ydotool  --no-packages  --no-copy (skip installing to ~/.local/share/hypr-hands)
ROOT=$(cd "$(dirname "$0")" && pwd)
DRY=0 YES=0 WITH_CUA=0 WITH_YDO=0 PKGS=1 LINK=1
for a in "$@"; do case $a in
  --dry-run) DRY=1;; --yes|-y|--non-interactive) YES=1;; --with-cua) WITH_CUA=1;; --with-ydotool) WITH_YDO=1;;
  --no-packages) PKGS=0;; --no-copy) LINK=0;; -h|--help) sed -n 3,10p "$0"; exit 0;; *) echo "unknown flag $a" >&2; exit 2;; esac; done
b(){ printf '\n\033[1m== %s\033[0m\n' "$*"; }
run(){ printf '  $ %s\n' "$*"; ((DRY)) || bash -c "$*"; }
ask(){ # ask "question" default(y|n)
  local d=$2 r; if ((YES)) || [[ ! -t 0 ]]; then [[ $d == y ]]; return; fi
  read -rp "  $1 [$( [[ $d == y ]] && echo Y/n || echo y/N )] " r; r=${r:-$d}; [[ ${r,,} == y* ]]; }
have(){ command -v "$1" >/dev/null 2>&1; }
((DRY)) && echo "DRY RUN: nothing will be changed."

b "1/7 Detect environment"
os=$(. /etc/os-release 2>/dev/null; echo "${ID:-?}"); echo "  OS: $os"
[[ -d /usr/share/omarchy ]] && echo "  Omarchy: $(omarchy version 2>/dev/null || cat /usr/share/omarchy/version)" || echo "  Omarchy: not detected (plain Hyprland is fine)"
[[ ${XDG_SESSION_TYPE:-} == wayland ]] && echo "  Session: wayland" || echo "  WARNING: session is '${XDG_SESSION_TYPE:-?}', hypr-hands needs Wayland"
if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] && have hyprctl; then echo "  Hyprland: $(hyprctl version | head -1)"
  hyprctl repl "return 'ok'" 2>/dev/null | grep -q ok && echo "  Lua repl: yes (hl.dsp.* dispatch)" || echo "  Lua repl: no (older Hyprland; move.sh needs the Lua repl)"
else echo "  WARNING: not inside a Hyprland session"; fi
[[ $os == arch || -f /etc/arch-release ]] || echo "  NOTE: non-Arch system; install the equivalents of the packages below yourself."

b "2/7 Required packages (pacman, needs sudo)"
need=(); for p in grim slurp wl-clipboard tesseract tesseract-data-eng jq wtype; do pacman -Q "$p" >/dev/null 2>&1 || need+=("$p"); done
if ((${#need[@]}==0)); then echo "  all present"
elif ((PKGS)) && ask "Install ${need[*]} with pacman?" y; then run "sudo pacman -S --needed ${need[*]}"
else echo "  skipped; later: sudo pacman -S --needed ${need[*]}"; fi

b "3/7 Click/scroll backend: wlrctl (AUR via yay)"
if have wlrctl; then echo "  present: $(command -v wlrctl)"
elif ((PKGS)) && have yay && ask "Install wlrctl from the AUR with yay?" y; then run "yay -S --needed aur/wlrctl"
else echo "  skipped; later: yay -S aur/wlrctl  (if yay says 'nothing to do', use the aur/ prefix)"; fi

b "4/7 Optional: Cua Driver (accessibility-first automation, by trycua)"
echo "  Official installer: /bin/bash -c \"\$(curl -fsSL https://cua.ai/driver/install.sh)\" -> ~/.local/bin/cua-driver"
echo "  plus a systemd user unit with CUA_DRIVER_RS_ENABLE_WAYLAND=1. No sudo."
cua=$(command -v cua-driver || { [[ -x $HOME/.local/bin/cua-driver ]] && echo "$HOME/.local/bin/cua-driver"; } || true)
if [[ -n $cua ]]; then echo "  present: $("$cua" --version) (update with: cua-driver update --apply)"
elif ((WITH_CUA)) || { ((!YES)) && ask "Install Cua Driver?" n; }; then
# shellcheck disable=SC2016  # printed literally on purpose
  run '/bin/bash -c "$(curl -fsSL https://cua.ai/driver/install.sh)"'
else echo "  skipped"; fi
unit=$HOME/.config/systemd/user/cua-driver.service
if [[ -n $cua || $WITH_CUA == 1 ]] && [[ ! -f $unit ]] && { ((WITH_CUA)) || ask "Create + enable the cua-driver systemd user unit (Wayland enabled)?" y; }; then
  echo "  writing $unit"
  ((DRY)) || { mkdir -p "$(dirname "$unit")"; cat > "$unit" <<'U'
[Unit]
Description=Cua Driver daemon
After=graphical-session.target

[Service]
Type=simple
Environment=CUA_DRIVER_RS_ENABLE_WAYLAND=1
Environment=PATH=%h/.local/bin:/usr/local/bin:/usr/bin
ExecStartPre=/bin/mkdir -p %h/.cache/cua-driver
ExecStart=%h/.local/bin/cua-driver serve --socket %h/.cache/cua-driver/cua-driver.sock
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
U
  }
  run "systemctl --user daemon-reload && systemctl --user enable --now cua-driver.service"
elif [[ -f $unit ]]; then echo "  unit exists: $unit ($(systemctl --user is-active cua-driver.service 2>/dev/null || true))"; fi

b "5/7 Optional: ydotool (drag fallback + fallback click/scroll)  — default NO"
cat <<'T'
  Enables: drag.sh fallback when Cua Driver is not available (drag uses Cua first),
           and click/scroll when wlrctl is missing.
  Risk:    ydotool injects input system-wide through /dev/uinput. Anything in the
           'input' group can then type/click into ANY window, including the lock
           screen prompt and terminals. hypr-hands only uses it when
           HYPR_HANDS_ALLOW_UINPUT=1 is set.
  Changes: sudo pacman -S ydotool
           /etc/udev/rules.d/80-uinput.rules: KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
           sudo usermod -aG input $USER
           systemctl --user enable --now ydotool.service   (socket: $XDG_RUNTIME_DIR/.ydotool_socket)
  Needs:   log out/in (or reboot) for the group change.
  Undo:    ./uninstall.sh --ydotool
T
if [[ -w /dev/uinput ]] && have ydotool; then echo "  already set up (/dev/uinput writable, ydotool present)"
  systemctl --user is-active ydotool.service >/dev/null 2>&1 || run "systemctl --user enable --now ydotool.service"
elif ((WITH_YDO)) || { ((!YES)) && ask "Set up ydotool now?" n; }; then
  run "sudo pacman -S --needed ydotool"
  run "echo 'KERNEL==\"uinput\", GROUP=\"input\", MODE=\"0660\", OPTIONS+=\"static_node=uinput\"' | sudo tee /etc/udev/rules.d/80-uinput.rules >/dev/null"
  run "sudo udevadm control --reload-rules && sudo udevadm trigger --name-match=uinput"
  run "sudo usermod -aG input \"\$USER\""
  run "systemctl --user enable ydotool.service"
  echo "  -> Log out and back in, then: systemctl --user start ydotool.service"
else echo "  skipped (recommended; drag uses Cua Driver when its daemon runs)"; fi

b "6/7 Install hypr-hands to ~/.local/share/hypr-hands + CLI ~/.local/bin/hypr-hands"
HH=$HOME/.local/share/hypr-hands; BIN=$HOME/.local/bin/hypr-hands
src="$(command git -C "$ROOT" remote get-url origin 2>/dev/null || echo local) $(command git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo '?') from $ROOT"
if ((LINK)); then
  if [[ $ROOT == "$HH" ]]; then echo "  running from the install dir; nothing to copy"
  else run "mkdir -p '$HH' && rsync -a --delete --exclude .git '$ROOT/' '$HH/' && echo '$src' > '$HH/.source'"; fi
  if [[ -e $BIN && ! -L $BIN ]]; then echo "  $BIN exists and is not our symlink; leaving it"
  else run "mkdir -p '$HOME/.local/bin' && ln -sfn '$HH/bin/hypr-hands' '$BIN'"; fi
  GB=$HOME/.local/bin/grokbot   # open-or-focus launcher for the Grok Bot desktop app
  if [[ -e $GB && ! -L $GB ]]; then echo "  $GB exists and is not our symlink; leaving it"
  else run "ln -sfn '$HH/bin/grokbot' '$GB'"; fi
  case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "  NOTE: add ~/.local/bin to PATH (or call $BIN directly)";; esac
fi
chmod +x "$ROOT"/scripts/*.sh "$ROOT"/*.sh 2>/dev/null || true

b "7/7 Check"
if ((DRY)); then echo "  (dry run) would run: $ROOT/scripts/check.sh"; fi
"$ROOT/scripts/check.sh" | jq -c '{session,lua_repl,locked,click_backend,uinput_writable,cua:.cua_driver.service,missing:[.tools|to_entries[]|select(.value==null)|.key]}'
if have grok-bot || have sand; then echo "  Grok Bot desktop app: present ($(command -v grok-bot || command -v sand))"
else echo "  Grok Bot desktop app: NOT installed. See: hypr-hands grokbot install-help"; fi
echo; echo "Done. Try: hypr-hands check   (scripts: ~/.local/share/hypr-hands/scripts)"
echo "Optional: hypr-hands grokbot bind   (SUPER + CTRL + G opens/focuses Grok Bot; launcher: grokbot)"
