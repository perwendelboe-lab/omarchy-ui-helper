#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
# windows.sh list | focus ADDR | move ADDR WS | fullscreen [ADDR] | close ADDR (only windows you opened)
case ${1:-list} in
  list) hyprctl clients -j | jq -c '[.[]|{address,class,title,workspace:.workspace.name,at,size,floating,fullscreen,focusHistoryID}]' ;;
  focus) a=${2:?addr}; lua "hl.dispatch(hl.dsp.focus({ window = 'address:$a' })); return 'ok'" ;;
  move) a=${2:?addr}; ws=${3:?workspace}; lua "hl.dispatch(hl.dsp.focus({ window = 'address:$a' })); hl.dispatch(hl.dsp.window.move({ workspace = '$ws', follow = false })); return 'ok'" ;;
  fullscreen) [[ -n ${2:-} ]] && lua "hl.dispatch(hl.dsp.focus({ window = 'address:$2' })); return 'ok'" >/dev/null; lua "hl.dispatch(hl.dsp.window.fullscreen()); return 'ok'" ;;
  close) a=${2:?addr}; lua "hl.dispatch(hl.dsp.focus({ window = 'address:$a' })); hl.dispatch(hl.dsp.window.close()); return 'ok'" ;;
  *) die "usage: windows.sh list|focus ADDR|move ADDR WS|fullscreen [ADDR]|close ADDR" 2 ;;
esac
echo
