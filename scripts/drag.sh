#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
[[ $# -eq 4 ]] || die "usage: drag.sh X1 Y1 X2 Y2" 2
require_unlocked
d=$(dirname "$0"); "$d/move.sh" "$1" "$2" >/dev/null
if have ydotool && [[ ${HYPR_HANDS_ALLOW_UINPUT:-0} == 1 ]]; then
  ydotool click 0x40; "$d/move.sh" "$3" "$4" >/dev/null; ydotool click 0x80
else
  die "drag needs press/release: wlrctl has no button-hold; use ydotool with HYPR_HANDS_ALLOW_UINPUT=1, or for windows use windows.sh / hl.dsp.window.move" 5
fi
echo '{"ok":true}'
