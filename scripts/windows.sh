#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
# windows.sh: manage windows. Only act on windows you opened; snapshot first, restore after.
usage="usage: windows.sh list | focus ADDR | move ADDR WS | fullscreen [ADDR] | close ADDR
  | float [ADDR] [toggle|on|off] | resize [ADDR] W H | resize [ADDR] +DX +DY (relative)
  | moveto [ADDR] X Y | swap [ADDR] l|r|u|d | movedir [ADDR] l|r|u|d | focusdir l|r|u|d
  | center [ADDR] | pseudo [ADDR] | split [ADDR] | snapshot [FILE] | restore [FILE]"
isaddr(){ [[ ${1:-} == 0x* ]]; }
# Optional leading ADDR: focus it for active-window-only actions.
pre(){ isaddr "${1:-}" && hh_dispatch focus "$1"; return 0; }
num(){ [[ $1 =~ ^[+-]?[0-9]+$ ]] || die "not a number: $1" 2; }
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr-hands"
act=${1:-list}; shift || true
extra='{}'
case $act in
  list) hyprctl clients -j | jq -c '[.[]|{address,class,title,workspace:.workspace.name,at,size,floating,fullscreen,focusHistoryID}]'; exit 0 ;;
  focus) hh_dispatch focus "${1:?addr}" ;;
  move) a=${1:?addr}; ws=${2:?workspace}; hh_dispatch focus "$a"; hh_dispatch to-ws "$ws" ;;
  fullscreen) [[ -n ${1:-} ]] && hh_dispatch focus "$1"; hh_dispatch fullscreen ;;
  close) hh_dispatch focus "${1:?addr}"; hh_dispatch close ;;
  float) a=""; isaddr "${1:-}" && { a=$1; shift; }; m=${1:-toggle}
    [[ $m =~ ^(toggle|on|off)$ ]] || die "$usage" 2; hh_dispatch float "$a" "$m" ;;
  resize) a=""; isaddr "${1:-}" && { a=$1; shift; }; w=${1:?W}; h=${2:?H}; num "$w"; num "$h"
    if [[ $w == [+-]* || $h == [+-]* ]]; then mode=rel; else mode=exact; fi
    [[ -z $a ]] && a=$(hyprctl activewindow -j | jq -r .address)
    hh_dispatch resize "$a" "${w#+}" "${h#+}" "$mode"; extra=$(jq -nc --arg m "$mode" '{mode:$m}') ;;
  moveto) a=""; isaddr "${1:-}" && { a=$1; shift; }; x=${1:?X}; y=${2:?Y}; num "$x"; num "$y"
    [[ -z $a ]] && a=$(hyprctl activewindow -j | jq -r .address)
    hh_dispatch moveto "$a" "$x" "$y" ;;
  swap|movedir) pre "${1:-}"; isaddr "${1:-}" && shift; d=${1:?direction l|r|u|d}
    [[ $d =~ ^[lrud]$ ]] || die "$usage" 2; hh_dispatch "$act" "$d" ;;
  focusdir) d=${1:?direction}; [[ $d =~ ^[lrud]$ ]] || die "$usage" 2; hh_dispatch focusdir "$d" ;;
  center) a=""; isaddr "${1:-}" && a=$1; [[ $(dispatch_mode) == classic ]] && pre "$a"; hh_dispatch center "$a" ;;
  pseudo|split) pre "${1:-}"; hh_dispatch "$act" ;;
  snapshot)
    mkdir -p "$state_dir"; f=${1:-$state_dir/layout-$(date +%Y%m%d-%H%M%S).json}
    hyprctl clients -j | jq '{created:(now|todate), active:"'"$(hyprctl activewindow -j | jq -r '.address // ""')"'",
      windows:[.[]|select(.mapped)|{address,class,title,workspace:.workspace.name,floating,fullscreen,at,size}]}' > "$f"
    jq -nc --arg f "$f" --argjson n "$(jq '.windows|length' "$f")" '{ok:true,action:"snapshot",file:$f,windows:$n}'; exit 0 ;;
  restore)
    f=${1:-$(ls -1t "$state_dir"/layout-*.json 2>/dev/null | head -1)}; [[ -r ${f:-} ]] || die "no snapshot file" 2
    cur=$(hyprctl clients -j); done_n=0; skipped=()
    while IFS= read -r w; do
      a=$(jq -r .address <<<"$w"); c=$(jq -c --arg a "$a" '.[]|select(.address==$a)' <<<"$cur")
      [[ -z $c ]] && { skipped+=("$a"); continue; }
      ws=$(jq -r .workspace <<<"$w"); fl=$(jq -r .floating <<<"$w"); fs=$(jq -r .fullscreen <<<"$w")
      if [[ $(jq -r .workspace.name <<<"$c") != "$ws" ]]; then
        if [[ $(dispatch_mode) == lua ]]; then hh_lua "hl.dispatch(hl.dsp.window.move({ workspace = '$ws', follow = false, window = 'address:$a' }))"
        else hh_classic movetoworkspacesilent "$ws,address:$a"; fi; fi
      if [[ $(jq -r .floating <<<"$c") != "$fl" ]]; then hh_dispatch float "$a" "$([[ $fl == true ]] && echo on || echo off)"; fi
      if [[ $fl == true ]]; then
        hh_dispatch resize "$a" "$(jq '.size[0]' <<<"$w")" "$(jq '.size[1]' <<<"$w")" exact
        hh_dispatch moveto "$a" "$(jq '.at[0]' <<<"$w")" "$(jq '.at[1]' <<<"$w")"; fi
      if [[ $(jq -r .fullscreen <<<"$c") != "$fs" ]]; then hh_dispatch focus "$a"; hh_dispatch fullscreen; fi
      done_n=$((done_n+1))
    done < <(jq -c '.windows[]' "$f")
    pa=$(jq -r '.active // ""' "$f"); [[ -n $pa ]] && jq -e --arg a "$pa" 'any(.[];.address==$a)' <<<"$cur" >/dev/null && hh_dispatch focus "$pa"
    jq -nc --arg f "$f" --argjson n "$done_n" --argjson s "$(printf '%s\n' "${skipped[@]}" | jq -R 'select(length>0)' | jq -sc .)" \
      '{ok:true,action:"restore",file:$f,restored:$n,missing:$s,note:"best effort: tiled positions follow the layout"}'; exit 0 ;;
  *) die "$usage" 2 ;;
esac
jq -nc --arg a "$act" --arg m "$(dispatch_mode)" --argjson x "$extra" '{ok:true,action:$a,dispatch:$m}+$x'
