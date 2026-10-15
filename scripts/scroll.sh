#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
# scroll.sh up|down|left|right [steps]
dir=${1:?usage: scroll.sh up|down|left|right [steps]}; n=${2:-3}; require_unlocked
if have wlrctl; then
  case $dir in up) a="0 -$((n*15))";; down) a="0 $((n*15))";; left) a="-$((n*15)) 0";; right) a="$((n*15)) 0";; *) die "bad direction" 2;; esac
  wlrctl pointer scroll $a
elif have ydotool && [[ ${HYPR_HANDS_ALLOW_UINPUT:-0} == 1 ]]; then
  case $dir in up) ydotool mousemove -w -- 0 "$n";; down) ydotool mousemove -w -- 0 "-$n";; left) ydotool mousemove -w -- "-$n" 0;; right) ydotool mousemove -w -- "$n" 0;; esac
else
  case $dir in up) k=Prior;; down) k=Next;; left) k=Left;; right) k=Right;; *) die "bad direction" 2;; esac
  for _ in $(seq "$n"); do wtype -k "$k"; done; echo '{"ok":true,"backend":"wtype-keys","note":"no pointer backend; used PageUp/PageDown"}'; exit 0
fi
echo '{"ok":true}'
