#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
# drag.sh X1 Y1 X2 Y2 [steps]  (logical px). Needs ydotool + HYPR_HANDS_ALLOW_UINPUT=1:
# wlrctl has no press/hold. Absolute positioning uses Lua hl.dsp.cursor.move (ydotool
# mousemove is relative and accelerated); ydotool only does button down (0x40) / up (0x80).
[[ $# -ge 4 ]] || die "usage: drag.sh X1 Y1 X2 Y2 [steps]" 2
x1=$1 y1=$2 x2=$3 y2=$4 n=${5:-12}
require_unlocked
have ydotool && [[ ${HYPR_HANDS_ALLOW_UINPUT:-0} == 1 ]] || die "drag needs ydotool with HYPR_HANDS_ALLOW_UINPUT=1 (wlrctl has no press/hold)" 5
d=$(dirname "$0"); "$d/move.sh" "$x1" "$y1" >/dev/null || die "cursor verify failed at start" 4
guard_target
ydo click 0x40
trap 'ydo click 0x80' EXIT
for ((i=1;i<=n;i++)); do cursor_move $((x1+(x2-x1)*i/n)) $((y1+(y2-y1)*i/n)); sleep 0.02; done
"$d/move.sh" "$x2" "$y2" >/dev/null || die "cursor verify failed at end" 4
guard_target
sleep 0.05; trap - EXIT; ydo click 0x80
jq -nc --argjson a "[$x1,$y1]" --argjson b "[$x2,$y2]" '{ok:true,backend:"ydotool+lua",from:$a,to:$b}'
