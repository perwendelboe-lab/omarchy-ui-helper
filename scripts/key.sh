#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
# key.sh COMBO   e.g. Return, ctrl+l, super+k, ctrl+shift+t
combo=${1:?usage: key.sh COMBO (e.g. ctrl+l, Return, super+k)}; require_unlocked; guard_target nopointer
IFS=+ read -ra parts <<<"$combo"; key=${parts[-1]}; mods=("${parts[@]:0:${#parts[@]}-1}")
args=(); for m in "${mods[@]}"; do case ${m,,} in ctrl|control) args+=(-M ctrl);; shift) args+=(-M shift);; alt) args+=(-M alt);; super|mod4|logo|win) args+=(-M logo);; *) die "unknown modifier $m" 2;; esac; done
rel=(); for ((i=${#args[@]}-1;i>0;i-=2)); do rel+=(-m "${args[i]}"); done
wtype "${args[@]}" -k "$key" "${rel[@]}"
jq -nc --arg c "$combo" '{ok:true,combo:$c,backend:"wtype"}'
