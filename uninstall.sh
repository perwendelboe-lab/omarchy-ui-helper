#!/usr/bin/env bash
set -euo pipefail
# hypr-hands uninstaller.
#   ./uninstall.sh              remove ~/.local/share/hypr-hands, the hypr-hands CLI and caches
#   --ydotool                   also undo the ydotool setup (udev rule, input group, user unit)
#   --cua                       also stop/disable the cua-driver user unit and remove Cua Driver
#   --packages                  print pacman removal commands (never run automatically)
#   --dry-run                   print, change nothing      --yes   don't ask
DRY=0 YES=0 YDO=0 CUA=0 PK=0
for a in "$@"; do case $a in --dry-run) DRY=1;; --yes|-y) YES=1;; --ydotool) YDO=1;; --cua) CUA=1;; --packages) PK=1;;
  -h|--help) sed -n 3,9p "$0"; exit 0;; *) echo "unknown flag $a" >&2; exit 2;; esac; done
run(){ printf '  $ %s\n' "$*"; ((DRY)) || bash -c "$*"; }
ask(){ ((YES)) && return 0; local r; read -rp "  $1 [y/N] " r; [[ ${r,,} == y* ]]; }
ROOT=$(cd "$(dirname "$0")" && pwd); HH=$HOME/.local/share/hypr-hands; BIN=$HOME/.local/bin/hypr-hands
echo "== hypr-hands files"
[[ -L $BIN ]] && run "rm '$BIN'" || echo "  no CLI symlink at $BIN"
GB=$HOME/.local/bin/grokbot; [[ -L $GB && $(readlink "$GB") == */hypr-hands/bin/grokbot ]] && run "rm '$GB'"
for f in "${XDG_CONFIG_HOME:-$HOME/.config}"/hypr/bindings.{lua,conf}; do [[ -f $f ]] && grep -q 'hypr-hands: grokbot' "$f" && echo "  NOTE: remove the 'hypr-hands: grokbot' line from $f yourself (Grok Bot keybinding)"; done
if [[ -d $HH && $ROOT != "$HH" ]]; then run "rm -rf '$HH'"; elif [[ $ROOT == "$HH" ]]; then echo "  running from $HH; delete it yourself afterwards"; else echo "  nothing at $HH"; fi
old=$HOME/.cursor/plugins/local/hypr-hands; [[ -L $old || -f $old/.hypr-hands-installed ]] && run "rm -rf '$old'"   # pre-0.3 location
run "rm -rf '${XDG_CACHE_HOME:-$HOME/.cache}/hypr-hands' '${XDG_RUNTIME_DIR:-/tmp}/hypr-hands'"
if ((YDO)) && ask "Undo ydotool setup (needs sudo)?"; then
  echo "== ydotool"
  run "systemctl --user disable --now ydotool.service || true"
  run "sudo rm -f /etc/udev/rules.d/80-uinput.rules && sudo udevadm control --reload-rules && sudo udevadm trigger --name-match=uinput"
  run "sudo gpasswd -d \"\$USER\" input || true"
  echo "  Log out/in to drop the group. Remove the package with: sudo pacman -Rns ydotool"
fi
if ((CUA)) && ask "Remove Cua Driver (user unit + ~/.cua-driver + ~/.local/bin/cua-driver)?"; then
  echo "== Cua Driver"
  run "systemctl --user disable --now cua-driver.service || true"
  run "rm -f ~/.config/systemd/user/cua-driver.service && systemctl --user daemon-reload"
  run "rm -rf ~/.cua-driver ~/.local/bin/cua-driver ~/.cache/cua-driver"
fi
if ((PK)); then echo "== Packages (run yourself if unused elsewhere)"
  echo "  sudo pacman -Rns wtype tesseract tesseract-data-eng   # grim/slurp/wl-clipboard/jq are used by Omarchy itself, keep them"; fi
echo "Repo left at $ROOT (delete it yourself if you want)."
