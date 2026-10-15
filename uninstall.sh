#!/usr/bin/env bash
set -euo pipefail
# hypr-hands uninstaller.
#   ./uninstall.sh              remove the installed plugin copy + hypr-hands caches
#   --ydotool                   also undo the ydotool setup (udev rule, input group, user unit)
#   --cua                       also stop/disable the cua-driver user unit and remove Cua Driver
#   --packages                  print pacman/yay removal commands (never run automatically)
#   --dry-run                   print, change nothing      --yes   don't ask
DRY=0 YES=0 YDO=0 CUA=0 PK=0
for a in "$@"; do case $a in --dry-run) DRY=1;; --yes|-y) YES=1;; --ydotool) YDO=1;; --cua) CUA=1;; --packages) PK=1;;
  -h|--help) sed -n 3,9p "$0"; exit 0;; *) echo "unknown flag $a" >&2; exit 2;; esac; done
run(){ printf '  $ %s\n' "$*"; ((DRY)) || bash -c "$*"; }
ask(){ ((YES)) && return 0; local r; read -rp "  $1 [y/N] " r; [[ ${r,,} == y* ]]; }
ROOT=$(cd "$(dirname "$0")" && pwd); dest=$HOME/.cursor/plugins/local/hypr-hands
echo "== Plugin link"
if [[ -L $dest ]]; then run "rm '$dest'"
elif [[ -f $dest/.hypr-hands-installed ]]; then run "rm -rf '$dest'"
elif [[ -e $dest ]]; then echo "  $dest not created by install.sh; leaving it"
else echo "  nothing at $dest"; fi
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
  echo "  sudo pacman -Rns wtype tesseract tesseract-data-eng   # grim/slurp/wl-clipboard/jq are used by Omarchy itself, keep them"
  echo "  yay -Rns wlrctl"; fi
echo "Repo left at $ROOT (delete it yourself if you want)."
