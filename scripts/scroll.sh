#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
# scroll.sh up|down|left|right [steps]
dir=${1:?usage: scroll.sh up|down|left|right [steps]}; n=${2:-1}; require_unlocked; guard_target
if have wlrctl; then
  # wlrctl syntax: wlrctl pointer scroll <dy> <dx> (negative = up/left). 15 units = one
  # libinput wheel notch (15 deg). Apps differ: foot emits several reports per notch.
  case $dir in up) dy=-$((n*15)); dx=0;; down) dy=$((n*15)); dx=0;; left) dy=0; dx=-$((n*15));; right) dy=0; dx=$((n*15));; *) die "bad direction" 2;; esac
  wlrctl pointer scroll "$dy" "$dx"
  jq -nc --arg d "$dir" --argjson dy "$dy" --argjson dx "$dx" '{ok:true,backend:"wlrctl",direction:$d,dy:$dy,dx:$dx}'; exit 0
elif have ydotool && [[ ${HYPR_HANDS_ALLOW_UINPUT:-0} == 1 ]]; then
  case $dir in up) ydo mousemove -w -- 0 "$n";; down) ydo mousemove -w -- 0 "-$n";; left) ydo mousemove -w -- "-$n" 0;; right) ydo mousemove -w -- "$n" 0;; esac
else
  case $dir in up) k=Prior;; down) k=Next;; left) k=Left;; right) k=Right;; *) die "bad direction" 2;; esac
  for _ in $(seq "$n"); do wtype -k "$k"; done; echo '{"ok":true,"backend":"wtype-keys","note":"no pointer backend; used PageUp/PageDown"}'; exit 0
fi
echo '{"ok":true}'
