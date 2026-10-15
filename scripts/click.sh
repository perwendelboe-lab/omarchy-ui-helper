#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
btn=${1:-left}; [[ $btn =~ ^(left|right|middle)$ ]] || die "usage: click.sh [left|right|middle] [X Y]" 2
require_unlocked
backend=none
if have wlrctl; then backend=wlrctl; elif have hypruse; then backend=hypruse
elif have ydotool && [[ ${HYPR_HANDS_ALLOW_UINPUT:-0} == 1 ]]; then backend=ydotool; fi
[[ $backend == none ]] && die "no click backend: install wlrctl (yay -S wlrctl) or hypruse, or opt in to ydotool with HYPR_HANDS_ALLOW_UINPUT=1" 5
if [[ $# -ge 3 ]]; then "$(dirname "$0")/move.sh" "$2" "$3" >/dev/null || die "cursor verify failed before click" 4; fi
case $backend in
  wlrctl) wlrctl pointer click "$btn" ;;   # man wlrctl: pointer click [left|right|middle]
  hypruse) hypruse click --button "$btn" ;;
  ydotool) case $btn in left) c=0xC0;; right) c=0xC1;; middle) c=0xC2;; esac; ydotool click "$c" ;;
esac
c=$(cursor); jq -nc --arg b "$backend" --arg btn "$btn" --arg c "$c" '{ok:true,backend:$b,button:$btn,cursor:$c}'
