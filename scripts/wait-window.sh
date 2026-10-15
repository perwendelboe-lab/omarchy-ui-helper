#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
cls=${1:?usage: wait-window.sh CLASS [timeout_s]}; t=${2:-10}; end=$((SECONDS+t))
while ((SECONDS<end)); do
  w=$(hyprctl clients -j | jq -c --arg c "$cls" '[.[]|select(.class==$c or .initialClass==$c)][0]//empty')
  [[ -n $w ]] && { jq -c '{ok:true,address,class,title,workspace:.workspace.name,at,size}' <<<"$w"; exit 0; }
  sleep 0.2; done
die "timeout waiting for class $cls" 7
