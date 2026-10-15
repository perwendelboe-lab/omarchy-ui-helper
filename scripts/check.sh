#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
tools=(hyprctl jq wtype grim slurp wl-copy wl-paste tesseract wlrctl ydotool dotool uvx hypruse foot)
obj='{}'
for t in "${tools[@]}"; do p=$(command -v "$t" 2>/dev/null || true); [[ -z $p && $t == cua-driver ]] && true; obj=$(jq -c --arg k "$t" --arg v "$p" '.[$k]=(if $v=="" then null else $v end)' <<<"$obj"); done
cua=$(command -v cua-driver || ls ~/.local/bin/cua-driver 2>/dev/null || true)
cuas=null; [[ -n $cua ]] && cuas=$(jq -Rn --arg s "$("$cua" status 2>&1 | head -1)" '$s')
svc=$(systemctl --user is-active cua-driver.service 2>/dev/null || true)
uinput=false; [[ -w /dev/uinput ]] && uinput=true
backend=none
if have wlrctl; then backend=wlrctl; elif have hypruse; then backend=hypruse; elif have ydotool && [[ ${HYPR_HANDS_ALLOW_UINPUT:-0} == 1 ]]; then backend=ydotool; fi
lua_ok=false; [[ $(HYPR_HANDS_DISPATCH=auto dispatch_mode) == lua ]] && lua_ok=true
jq -n --argjson tools "$obj" --arg cua "$cua" --argjson cuas "$cuas" --arg svc "$svc" --argjson uinput $uinput \
  --arg backend $backend --argjson locked "$(locked && echo true || echo false)" --argjson lua $lua_ok \
  --arg sess "${XDG_SESSION_TYPE:-}" --arg sig "${HYPRLAND_INSTANCE_SIGNATURE:+set}" \
  '{session:$sess,hyprland_signature:$sig,lua_repl:$lua,dispatch:(if $lua then "lua" else "classic" end),dispatch_forced:(env.HYPR_HANDS_DISPATCH // null),locked:$locked,tools:$tools,cua_driver:{path:($cua|select(.!="")),status:$cuas,service:$svc},uinput_writable:$uinput,click_backend:$backend}'
