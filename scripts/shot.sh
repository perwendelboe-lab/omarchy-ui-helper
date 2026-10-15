#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
# shot.sh [full|region "X,Y WxH"|select|window] [outfile]
have grim || die "grim missing: sudo pacman -S grim" 5
mode=${1:-full}; dir=${XDG_RUNTIME_DIR:-/tmp}/hypr-hands; mkdir -p "$dir"
out=${3:-${2:-}}; [[ $mode == region ]] && out=${3:-}; out=${out:-$dir/shot-$(date +%s%N).png}
case $mode in
  full) grim "$out" ;;
  region) grim -g "${2:?region needs \"X,Y WxH\"}" "$out" ;;
  select) have slurp || die "slurp missing" 5; grim -g "$(slurp)" "$out" ;;
  window) g=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'); grim -g "$g" "$out" ;;
  *) die "bad mode" 2 ;;
esac
echo "$out"
