#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
# drag.sh X1 Y1 X2 Y2 [steps]  (logical px, the `hyprctl cursorpos` frame). One held left-button gesture.
# Backends (HYPR_HANDS_DRAG_BACKEND=auto|cua|ydotool, default auto):
#  1. cua-driver-vptr: Cua Driver desktop-scope drag over zwlr_virtual_pointer_v1 (press at A, interpolated
#     held motion, release at B). Used when cua-driver is installed and its daemon is running (started with
#     CUA_DRIVER_RS_ENABLE_WAYLAND=1). auto uses it with one active monitor; `cua` forces it on multi-monitor.
#     Cua's desktop frame is physical px, so logical coords are scaled by (Cua frame / logical layout).
#  2. ydotool (opt-in, HYPR_HANDS_ALLOW_UINPUT=1): uinput button down/up, cursor moves via Lua/classic dispatch.
# Modifier drags (keys held during the drag) are refused. HYPR_HANDS_DRAG_MS sets the Cua duration (default 500).
[[ $# -ge 4 && $# -le 5 ]] || die "usage: drag.sh X1 Y1 X2 Y2 [steps] (modifier drags are not supported)" 2
for a in "$@"; do [[ $a =~ ^-?[0-9]+$ ]] || die "drag: '$a' is not an integer (modifier drags are not supported)" 2; done
x1=$1 y1=$2 x2=$3 y2=$4 n=${5:-20} ms=${HYPR_HANDS_DRAG_MS:-500}
(( n >= 1 && n <= 200 )) || die "steps must be 1..200" 2
[[ $ms =~ ^[0-9]+$ ]] && (( ms <= 10000 )) || die "HYPR_HANDS_DRAG_MS must be 0..10000" 2
want=${HYPR_HANDS_DRAG_BACKEND:-auto}
[[ $want =~ ^(auto|cua|ydotool)$ ]] || die "HYPR_HANDS_DRAG_BACKEND must be auto|cua|ydotool" 2
require_unlocked
d=$(dirname "$0")
end_ok(){ local c x y dx dy; c=$(cursor); x=${c%,*}; y=${c#*,}; dx=$((x-x2)); dy=$((y-y2)); (( ${dx#-} <= 2 && ${dy#-} <= 2 )); }
end_fail(){ jq -nc --arg b "$1" --arg c "$(cursor)" --argjson t "[$x2,$y2]" '{ok:false,error:"cursor not at drag end",backend:$b,target:$t,cursor:$c}' >&2; exit 4; }
skip=""

cua_drag(){ # returns 1 when Cua cannot be used (caller may fall back); exits on any failure after the press
  local b lx ly lw lh cnt cw ch args out
  b=$(cua_bin); [[ -n $b ]] || { skip="cua-driver not installed"; return 1; }
  cua_ready || { skip="cua-driver daemon not running"; return 1; }
  read -r lx ly lw lh cnt < <(layout_box) || { skip="hyprctl monitors failed"; return 1; }
  [[ $want == cua || $cnt == 1 ]] || { skip="$cnt monitors (set HYPR_HANDS_DRAG_BACKEND=cua to force)"; return 1; }
  read -r cw ch < <(cua_desktop_size) || { skip="cua get_desktop_state failed"; return 1; }
  args=$(jq -nc --argjson lx "$lx" --argjson ly "$ly" --argjson lw "$lw" --argjson lh "$lh" --argjson cw "$cw" --argjson ch "$ch" \
    --argjson x1 "$x1" --argjson y1 "$y1" --argjson x2 "$x2" --argjson y2 "$y2" --argjson n "$n" --argjson ms "$ms" '
    def r: (. * 100 | round) / 100;
    ($cw / $lw) as $fx | ($ch / $lh) as $fy |
    if ((($fx - $fy) | fabs) > 0.01 * $fx) then null else
    {scope:"desktop", from_x:(($x1-$lx)*$fx|r), from_y:(($y1-$ly)*$fy|r), to_x:(($x2-$lx)*$fx|r), to_y:(($y2-$ly)*$fy|r), duration_ms:$ms, steps:$n} end')
  [[ $args != null ]] || { skip="Cua frame ${cw}x${ch} does not match layout ${lw}x${lh}"; return 1; }
  "$d/move.sh" "$x1" "$y1" >/dev/null || die "cursor verify failed at start" 4
  guard_target
  if ! out=$(CUA_DRIVER_RS_ENABLE_WAYLAND=1 "$b" call drag "$args" 2>&1); then
    # Refused before any input (e.g. daemon started without CUA_DRIVER_RS_ENABLE_WAYLAND=1): fall back is safe.
    [[ $out == *"cannot be delivered"* ]] && { skip="cua-driver: ${out:0:160}"; return 1; }
    die "cua-driver drag failed: ${out:0:200}" 11
  fi
  sleep 0.05; end_ok || end_fail cua-driver-vptr
  jq -nc --argjson a "[$x1,$y1]" --argjson b "[$x2,$y2]" --arg c "$(cursor)" --argjson f "$(jq -n "$cw / $lw")" \
    '{ok:true,backend:"cua-driver-vptr",from:$a,to:$b,cursor:$c,frame_scale:$f}'
  exit 0; }

if [[ $want == ydotool ]]; then skip="HYPR_HANDS_DRAG_BACKEND=ydotool"; else cua_drag || true; fi
[[ $want == cua ]] && die "cua drag unavailable: $skip" 5
have ydotool && [[ ${HYPR_HANDS_ALLOW_UINPUT:-0} == 1 ]] || die "no drag backend ($skip); ydotool fallback needs HYPR_HANDS_ALLOW_UINPUT=1 (wlrctl has no press/hold)" 5
# ydotool fallback: absolute moves via Lua hl.dsp.cursor.move / classic movecursor (ydotool mousemove is
# relative and accelerated); ydotool only does button down (0x40) / up (0x80).
"$d/move.sh" "$x1" "$y1" >/dev/null || die "cursor verify failed at start" 4
guard_target
ydo click 0x40
trap 'ydo click 0x80' EXIT
for ((i=1;i<=n;i++)); do cursor_move $((x1+(x2-x1)*i/n)) $((y1+(y2-y1)*i/n)); sleep 0.02; done
"$d/move.sh" "$x2" "$y2" >/dev/null || die "cursor verify failed at end" 4
guard_target
sleep 0.05; trap - EXIT; ydo click 0x80
jq -nc --arg m "$(dispatch_mode)" --argjson a "[$x1,$y1]" --argjson b "[$x2,$y2]" --arg s "$skip" '{ok:true,backend:("ydotool+"+$m),from:$a,to:$b,cua_skipped:($s|select(.!=""))}'
