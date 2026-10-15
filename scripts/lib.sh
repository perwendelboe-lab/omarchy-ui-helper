# shellcheck shell=bash
have(){ command -v "$1" >/dev/null 2>&1; }
die(){ jq -nc --arg e "$1" '{ok:false,error:$e}' >&2; exit "${2:-1}"; }
locked(){ pgrep -x hyprlock >/dev/null 2>&1; }
require_unlocked(){ locked && die "screen is locked (hyprlock running); refusing" 3 || true; }
lua(){ hyprctl repl "$1"; }
cursor(){ hyprctl cursorpos | tr -d ' ' ; }   # "x,y" logical coords
cursor_move(){ lua "hl.dispatch(hl.dsp.cursor.move({ x = $1, y = $2 })); return 'ok'" >/dev/null; }
# Optional guard: if HYPR_HANDS_REQUIRE_CLASS is set (prefix), the focused window
# and the window under the cursor must both have a class starting with it.
guard_target(){
  local pre=${HYPR_HANDS_REQUIRE_CLASS:-}; [[ -z $pre ]] && return 0
  local act c x y under
  act=$(hyprctl activewindow -j | jq -r '.class // ""')
  [[ $act == "$pre"* ]] || die "guard: focused window '$act' is not $pre*" 8
  [[ ${1:-} == nopointer ]] && return 0
  c=$(cursor); x=${c%,*}; y=${c#*,}
  under=$(hyprctl clients -j | jq -r --argjson x "$x" --argjson y "$y" --argjson ws "$(hyprctl activeworkspace -j | jq .id)" '
    [.[]|select(.workspace.id==$ws and .mapped and ($x>=.at[0]) and ($x<.at[0]+.size[0]) and ($y>=.at[1]) and ($y<.at[1]+.size[1]))]
    | sort_by(.fullscreen|not) | sort_by(.focusHistoryID) | .[0].class // ""')
  [[ $under == "$pre"* ]] || die "guard: window under cursor '$under' is not $pre*" 8
}
# ydotool client: socket is $YDOTOOL_SOCKET, else $XDG_RUNTIME_DIR/.ydotool_socket (Arch user unit), else /tmp/.ydotool_socket
ydo(){
  if [[ -z ${YDOTOOL_SOCKET:-} ]]; then
    for s in "${XDG_RUNTIME_DIR:-/run/user/$UID}/.ydotool_socket" /tmp/.ydotool_socket; do [[ -S $s ]] && { export YDOTOOL_SOCKET=$s; break; }; done
  fi
  [[ -S ${YDOTOOL_SOCKET:-} ]] || die "ydotoold socket not found; run: systemctl --user enable --now ydotool.service" 5
  ydotool "$@" >/dev/null
}
