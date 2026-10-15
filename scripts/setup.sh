#!/usr/bin/env bash
set -euo pipefail
# Prints install commands only. Installs nothing.
. "$(dirname "$0")/lib.sh"
pac=(); for p in jq:jq wtype:wtype grim:grim slurp:slurp wl-copy:wl-clipboard tesseract:tesseract; do have "${p%%:*}" || pac+=("${p#*:}"); done
have tesseract && [[ -z $(tesseract --list-langs 2>/dev/null | grep -x eng) ]] && pac+=(tesseract-data-eng)
echo "# hypr-hands setup (nothing is installed by this script)"
((${#pac[@]})) && echo "sudo pacman -S --needed ${pac[*]}" || echo "# pacman: all required packages present"
have wlrctl || echo "yay -S wlrctl            # AUR, preferred click backend (virtual pointer)"
have uvx || echo "sudo pacman -S uv         # for optional hypruse (uvx hypruse)"
have ydotool || echo "# optional, opt-in only: sudo pacman -S ydotool  (needs /dev/uinput access; set HYPR_HANDS_ALLOW_UINPUT=1)"
