#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
[[ $# -eq 2 && $1 =~ ^-?[0-9]+$ && $2 =~ ^-?[0-9]+$ ]] || die "usage: move.sh X Y (logical px)" 2
require_unlocked
cursor_move "$1" "$2"; sleep 0.05
c=$(cursor); x=${c%,*}; y=${c#*,}
dx=$((x-$1)); dy=$((y-$2))
if (( ${dx#-} <= 2 && ${dy#-} <= 2 )); then jq -nc --argjson x $x --argjson y $y '{ok:true,cursor:{x:$x,y:$y}}'
else jq -nc --argjson x $x --argjson y $y --argjson tx $1 --argjson ty $2 '{ok:false,error:"cursor not at target",target:{x:$tx,y:$ty},cursor:{x:$x,y:$y}}'; exit 4; fi
