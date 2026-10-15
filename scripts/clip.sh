#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
have wl-copy || die "wl-clipboard missing: sudo pacman -S wl-clipboard" 5
case ${1:-} in
  get) wl-paste --no-newline 2>/dev/null || true ;;
  set) if [[ $# -ge 2 ]]; then printf %s "$2" | wl-copy; else wl-copy; fi; echo '{"ok":true}' ;;
  *) die "usage: clip.sh get | set [TEXT] (stdin if no TEXT)" 2 ;;
esac
