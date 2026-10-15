#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
# windows.sh list | focus ADDR | move ADDR WS | fullscreen [ADDR] | close ADDR (only windows you opened)
case ${1:-list} in
  list) hyprctl clients -j | jq -c '[.[]|{address,class,title,workspace:.workspace.name,at,size,floating,fullscreen,focusHistoryID}]' ;;
  focus) a=${2:?addr}; hh_dispatch focus "$a" ;;
  move) a=${2:?addr}; ws=${3:?workspace}; hh_dispatch focus "$a"; hh_dispatch to-ws "$ws" ;;
  fullscreen) [[ -n ${2:-} ]] && hh_dispatch focus "$2"; hh_dispatch fullscreen ;;
  close) a=${2:?addr}; hh_dispatch focus "$a"; hh_dispatch close ;;
  *) die "usage: windows.sh list|focus ADDR|move ADDR WS|fullscreen [ADDR]|close ADDR" 2 ;;
esac
[[ ${1:-list} == list ]] || jq -nc --arg a "${1}" --arg m "$(dispatch_mode)" '{ok:true,action:$a,dispatch:$m}'
