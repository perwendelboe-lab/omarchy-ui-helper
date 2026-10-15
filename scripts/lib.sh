# shellcheck shell=bash
have(){ command -v "$1" >/dev/null 2>&1; }
die(){ jq -nc --arg e "$1" '{ok:false,error:$e}' >&2; exit "${2:-1}"; }
locked(){ pgrep -x hyprlock >/dev/null 2>&1; }
require_unlocked(){ locked && die "screen is locked (hyprlock running); refusing" 3 || true; }
lua(){ hyprctl repl "$1"; }
# Dispatch backend: Lua (Hyprland with hyprland.lua config: `hyprctl repl` + hl.dsp.*) or
# classic (hyprlang .conf: `hyprctl dispatch ...`). HYPR_HANDS_DISPATCH=lua|classic|auto (default auto).
# HYPR_HANDS_DRYRUN=1 prints the dispatch command instead of running it.
dispatch_mode(){
  if [[ -z ${_HH_MODE:-} ]]; then
    case ${HYPR_HANDS_DISPATCH:-auto} in
      lua|classic) _HH_MODE=$HYPR_HANDS_DISPATCH ;;
      *) if hyprctl repl "return (hl and hl.dsp and hl.dsp.cursor) and 'hh-lua' or 'no'" 2>/dev/null | grep -q hh-lua; then _HH_MODE=lua; else _HH_MODE=classic; fi ;;
    esac
  fi
  echo "$_HH_MODE"; }
_hh_run(){
  if [[ ${HYPR_HANDS_DRYRUN:-0} == 1 ]]; then { printf 'DRYRUN:'; printf ' %q' "$@"; echo; } >&2; return 0; fi
  local out; out=$("$@" 2>&1) || die "dispatch failed ($(dispatch_mode)): ${out:0:200}" 9
  [[ $out == *rror* || $out == *nvalid* ]] && die "dispatch error ($(dispatch_mode)): ${out:0:200}" 9; return 0; }
hh_lua(){ _hh_run hyprctl repl "$1; return 'ok'"; }
hh_classic(){ _hh_run hyprctl dispatch "$@"; }
hh_dispatch(){ # action args... -> runs the right form for this Hyprland
  local m; m=$(dispatch_mode); _HH_MODE=$m
  case $1 in
    cursor) if [[ $m == lua ]]; then hh_lua "hl.dispatch(hl.dsp.cursor.move({ x = $2, y = $3 }))"; else hh_classic movecursor "$2" "$3"; fi ;;
    focus) if [[ $m == lua ]]; then hh_lua "hl.dispatch(hl.dsp.focus({ window = 'address:$2' }))"; else hh_classic focuswindow "address:$2"; fi ;;
    to-ws) if [[ $m == lua ]]; then hh_lua "hl.dispatch(hl.dsp.window.move({ workspace = '$2', follow = false }))"; else hh_classic movetoworkspacesilent "$2"; fi ;;
    fullscreen) if [[ $m == lua ]]; then hh_lua "hl.dispatch(hl.dsp.window.fullscreen())"; else hh_classic fullscreen 0; fi ;;
    close) if [[ $m == lua ]]; then hh_lua "hl.dispatch(hl.dsp.window.close())"; else hh_classic killactive; fi ;;
    *) die "hh_dispatch: unknown action $1" 2 ;;
  esac; }
cursor(){ hyprctl cursorpos | tr -d ' ' ; }   # "x,y" logical coords
cursor_move(){ hh_dispatch cursor "$1" "$2"; }
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
