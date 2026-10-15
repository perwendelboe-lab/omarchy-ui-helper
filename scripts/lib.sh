# shellcheck shell=bash
have(){ command -v "$1" >/dev/null 2>&1; }
die(){ jq -nc --arg e "$1" '{ok:false,error:$e}' >&2; exit "${2:-1}"; }
locked(){ pgrep -x hyprlock >/dev/null 2>&1; }
require_unlocked(){ locked && die "screen is locked (hyprlock running); refusing" 3 || true; }
lua(){ hyprctl repl "$1"; }
cursor(){ hyprctl cursorpos | tr -d ' ' ; }   # "x,y" logical coords
cursor_move(){ lua "hl.dispatch(hl.dsp.cursor.move({ x = $1, y = $2 })); return 'ok'" >/dev/null; }
