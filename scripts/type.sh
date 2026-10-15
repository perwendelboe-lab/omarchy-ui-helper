#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
force=0; [[ ${1:-} == --i-know-this-is-not-a-secret ]] && { force=1; shift; }
text=${1:?usage: type.sh [--i-know-this-is-not-a-secret] TEXT}
require_unlocked
if (( !force )) && [[ $text =~ (sk-|ghp_|github_pat_|xox[bp]-|AKIA|BEGIN.*PRIVATE|password|passwd|secret|token) || ( ${#text} -ge 24 && ! $text =~ [[:space:]] && $text =~ [0-9] && $text =~ [A-Za-z] ) ]]; then
  die "text looks like a secret; refusing (pass --i-know-this-is-not-a-secret if it is not)" 6; fi
wtype -- "$text"; jq -nc --argjson n ${#text} '{ok:true,chars:$n}'
