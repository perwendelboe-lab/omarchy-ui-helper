#!/usr/bin/env bash
set -euo pipefail
# grokbot.sh [open|status|bind|install-help] [--dry-run] [--key "SUPER + CTRL + G"]
#   open (default)  focus the Grok Bot desktop window, or launch it if it is not running
#   status          JSON: package, binary, running window, launcher, keybinding
#   bind            add a launch-or-focus keybinding (default SUPER + CTRL + G) to
#                   ~/.config/hypr/bindings.lua (Lua config) or bindings.conf (classic); idempotent
#   install-help    print how to install the Grok Bot desktop app on Omarchy/Arch
# Never moves or resizes windows. HYPR_HANDS_DRYRUN=1 / --dry-run print instead of acting.
. "$(dirname "$0")/lib.sh"
CLASS_RE=${HYPR_HANDS_GROKBOT_CLASS:-'^(grok-bot|grok bot|sand)$'}
KEY=${HYPR_HANDS_GROKBOT_KEY:-SUPER + CTRL + G}
MARK='hypr-hands: grokbot'
cmd=open
while (($#)); do case $1 in
  open|status|bind|install-help) cmd=$1;; --dry-run) export HYPR_HANDS_DRYRUN=1;;
  --key) KEY=${2:?--key needs a value}; shift;; -h|--help) sed -n 3,9p "$0"; exit 0;;
  *) die "grokbot: unknown argument $1" 2;; esac; shift; done
DRY=${HYPR_HANDS_DRYRUN:-0}
CFG=${XDG_CONFIG_HOME:-$HOME/.config}/hypr

grok_bin(){ local c; for c in grok-bot sand; do command -v "$c" 2>/dev/null && return 0; done
  for c in "/opt/Grok Bot/grok-bot" "/opt/Grok Bot/sand"; do [[ -x $c ]] && { echo "$c"; return 0; }; done; return 1; }
grok_pkg(){ pacman -Qq grok-bot grok-bot-bin grok-bot-desktop grok-bot-cursor grokbot-linux-port-bin grokbot-linux-port 2>/dev/null | head -1 || true; }
grok_window(){ have hyprctl || return 0
  hyprctl clients -j 2>/dev/null | jq -r --arg re "$CLASS_RE" \
    'sort_by(.focusHistoryID) | first(.[] | select(((.class // "") | test($re; "i")) or ((.initialClass // "") | test($re; "i")))) | .address' 2>/dev/null || true; }
cfg_style(){ if [[ -f $CFG/hyprland.lua ]]; then echo lua; elif [[ -f $CFG/hyprland.conf ]]; then echo classic; else echo none; fi; }
bind_file(){ # classic: bindings.conf when hyprland.conf sources it (Omarchy 3.x), else hyprland.conf itself
  case $(cfg_style) in lua) echo "$CFG/bindings.lua";;
    classic) if grep -qE '^[[:space:]]*source[[:space:]]*=.*bindings\.conf' "$CFG/hyprland.conf" 2>/dev/null; then echo "$CFG/bindings.conf"; else echo "$CFG/hyprland.conf"; fi;;
    *) echo "";; esac; }
launcher(){ command -v grokbot 2>/dev/null || { [[ -x $HOME/.local/bin/grokbot ]] && echo "$HOME/.local/bin/grokbot"; } || echo "$HOME/.local/bin/grokbot"; }

case $cmd in
open)
  addr=$(grok_window)
  if [[ -n $addr ]]; then hh_dispatch focus "$addr"; jq -nc --arg a "$addr" '{ok:true,action:"focus",address:$a}'; exit 0; fi
  bin=$(grok_bin) || { if have gtk-launch && [[ -n $(find /usr/share/applications "$HOME/.local/share/applications" -maxdepth 1 -name 'grok-bot.desktop' 2>/dev/null) ]]; then bin=gtk-launch; else
    die "Grok Bot desktop app not found (no grok-bot command). Install it first: hypr-hands grokbot install-help" 10; fi; }
  argv=("$bin"); [[ $bin == gtk-launch ]] && argv+=(grok-bot)
  have uwsm-app && argv=(uwsm-app -- "${argv[@]}")
  if ((DRY)); then { printf 'DRYRUN: setsid'; printf ' %q' "${argv[@]}"; echo; } >&2
  else setsid "${argv[@]}" >/dev/null 2>&1 < /dev/null & disown; fi
  jq -nc --arg c "${argv[*]}" --argjson d "$DRY" '{ok:true,action:"launch",command:$c,dry_run:($d==1)}' ;;
status)
  bf=$(bind_file); bound=false; [[ -n $bf && -f $bf ]] && grep -q "$MARK" "$bf" && bound=true
  jq -nc --arg pkg "$(grok_pkg)" --arg bin "$(grok_bin || true)" --arg addr "$(grok_window)" --arg l "$(launcher)" \
    --argjson lx "$([[ -x $(launcher) ]] && echo true || echo false)" --arg style "$(cfg_style)" --arg bf "$bf" --argjson bound $bound --arg key "$KEY" \
    'def nz: if .=="" then null else . end; {installed:($pkg!="" or $bin!=""),package:($pkg|nz),binary:($bin|nz),running:($addr!=""),address:($addr|nz),
      launcher:{path:$l,present:$lx},config:$style,bindings_file:($bf|nz),keybinding:{key:$key,installed:$bound}}' ;;
bind)
  bf=$(bind_file); [[ -n $bf ]] || die "no ~/.config/hypr/hyprland.lua or hyprland.conf found; add the binding by hand (see README)" 11
  l=$(launcher)
  if [[ -f $bf ]] && grep -q "$MARK" "$bf"; then jq -nc --arg f "$bf" '{ok:true,action:"none",reason:"already bound",file:$f}'; exit 0; fi
  # warn (do not fail) when the combo is already used by another binding
  conflict=""
  if have hyprctl; then
    mods=0; for m in ${KEY//+/ }; do case ${m^^} in SUPER|WIN|MOD4) ((mods|=64));; CTRL|CONTROL) ((mods|=4));; SHIFT) ((mods|=1));; ALT|MOD1) ((mods|=8));; esac; done
    k=${KEY##*+}; k=${k// /}
    conflict=$(hyprctl binds -j 2>/dev/null | jq -r --argjson m $mods --arg k "${k,,}" '[.[]|select(.modmask==$m and ((.key // "")|ascii_downcase)==$k)|(.description // .arg // "?")]|join(", ")' 2>/dev/null || true)
  fi
  if [[ $(cfg_style) == lua ]]; then
    line=$(printf -- '-- %s (open or focus Grok Bot)\no.bind("%s", "Grok Bot", "%s")' "$MARK" "$KEY" "$l")
  else
    ck=${KEY//+/ }; ck=$(tr -s ' ' <<<"$ck"); mods=${ck% *}; key=${ck##* }
    line=$(printf -- '# %s (open or focus Grok Bot)\nbindd = %s, %s, Grok Bot, exec, %s' "$MARK" "$mods" "$key" "$l")
  fi
  if ((DRY)); then echo "DRYRUN: append to $bf: $line" >&2
  else mkdir -p "$(dirname "$bf")"; [[ -f $bf ]] && cp -p "$bf" "$bf.hypr-hands.bak"; printf '\n%s\n' "$line" >>"$bf"; fi
  jq -nc --arg f "$bf" --arg l "$line" --arg c "$conflict" --argjson d "$DRY" \
    'def nz: if .=="" then null else . end; {ok:true,action:"bind",file:$f,line:$l,dry_run:($d==1),conflict:($c|nz),note:"Hyprland reloads the config on save; if not, run: hyprctl reload"}' ;;
install-help)
  cat <<'H'
Grok Bot desktop app on Omarchy / Arch. The official Linux build is a .deb (https://x.ai/bot).
Some Omarchy versions do not preinstall it. Pick the first that works:
1. Omarchy repo (Omarchy 4.x, when `pacman -Si grok-bot` finds it):
     Omarchy menu > Install > AI > Grok Bot      or:  omarchy-pkg-add grok-bot
2. Build Omarchy's PKGBUILD yourself (downloads the official .deb from downloads.cursor.com
   and checks its sha256, unpacks it with bsdtar, installs with pacman):
     git clone --depth 1 https://github.com/omacom/omarchy-pkgs ~/code/omarchy-pkgs
     cd ~/code/omarchy-pkgs/pkgbuilds/grok-bot && makepkg -si
Not offered on purpose: AUR repacks (grok-bot-desktop, debtap and similar). The AUR has had
malware incidents and its packages run arbitrary build scripts; use the two routes above.
Then: hypr-hands grokbot bind   (adds SUPER + CTRL + G)   and open it with: grokbot
H
  ;;
esac
