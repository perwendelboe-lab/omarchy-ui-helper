#!/usr/bin/env bash
set -euo pipefail
# breaking-watch.sh [--json] [--keywords REGEX]
# Release notes / commits since the installed version for cua-driver, Hyprland and Omarchy,
# grepped for keywords that could break hypr-hands. Read-only. Designed for scheduled runs.
. "$(dirname "$0")/lib.sh"
KW='breaking|removed?|deprecat|lua|dispatch|wayland|hyprctl|movecursor|cursor|ipc|socket|at-spi|atspi|uinput|virtual.pointer|wlr|permission'
json_only=0
while (($#)); do case $1 in --json) json_only=1;; --keywords) KW=$2; shift;; esac; shift; done
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/hypr-hands; mkdir -p "$CACHE"
semver(){ grep -oE '[0-9]+\.[0-9]+\.[0-9]+' <<<"${1:-}" | head -1 || true; }
newer(){ [[ $1 != "$2" && $(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1) == "$2" ]]; }
gh_api(){ if have gh && gh auth status >/dev/null 2>&1; then gh api "$1"; else curl -fsSL -H 'Accept: application/vnd.github+json' "https://api.github.com/$1"; fi; }
results=()
releases_since(){ # name repo tagprefix installed
  local name=$1 repo=$2 pre=$3 inst=$4 rel hits src=api
  if ! rel=$(gh_api "repos/$repo/releases?per_page=100" 2>/dev/null) || ! jq -e 'type=="array"' >/dev/null <<<"$rel"; then
    src=atom; rel=$(curl -fsSL "https://github.com/$repo/releases.atom" | python3 -c '
import sys,json,xml.etree.ElementTree as E,html,re
ns={"a":"http://www.w3.org/2005/Atom"}; r=E.fromstring(sys.stdin.read()); out=[]
for e in r.findall("a:entry",ns):
  t=e.find("a:link",ns).get("href").rsplit("/",1)[-1]; c=e.find("a:content",ns)
  out.append({"tag_name":t,"body":re.sub("<[^>]+>"," ",html.unescape(c.text or "")) if c is not None else "","published_at":e.find("a:updated",ns).text})
print(json.dumps(out))'); fi
  local sel; sel=$(jq -c --arg p "$pre" '[.[]|select(.tag_name|test("^"+$p+"[0-9]+\\.[0-9]+\\.[0-9]+$"))|{tag:.tag_name,v:(.tag_name|ltrimstr($p)),date:.published_at,body:(.body//"")}]' <<<"$rel")
  local filtered="[]"
  while IFS= read -r r; do v=$(jq -r .v <<<"$r"); if [[ -z $inst ]] || newer "$inst" "$v"; then filtered=$(jq -c --argjson r "$r" '.+[$r]' <<<"$filtered"); fi; done < <(jq -c '.[]' <<<"$sel")
  hits=$(jq -r '.[]|.tag as $t|.body|split("\n")[]|select(length>0)|"\($t): \(.)"' <<<"$filtered" | grep -iE "$KW" | cut -c1-220 | head -40 || true)
  # release bodies go through stdin: --argjson hits ARG_MAX when many versions are new
  results+=("$(jq -c --arg n "$name" --arg i "$inst" --arg src "$src" --arg h "$hits" \
    '{name:$n,installed:$i,source:$src,new_versions:[.[]|.tag],hits:($h|split("\n")|map(select(length>0)))}' <<<"$filtered")")
}
ci=$(semver "$( (cua-driver --version || ~/.local/bin/cua-driver --version) 2>/dev/null || true)")
releases_since cua-driver trycua/cua cua-driver-rs-v "$ci"
hi=$(semver "$(hyprctl version 2>/dev/null | grep -m1 -oE 'Tag: v[0-9.]+' || true)")
releases_since hyprland hyprwm/Hyprland v "$hi"
# Omarchy publishes tags, not GitHub releases: scan commit subjects since the installed version.
oraw=$(omarchy version 2>/dev/null || true); oi=$(semver "$oraw"); repo="$CACHE/omarchy.git"
if [[ -d $repo ]]; then command git -C "$repo" fetch -q --tags origin 2>/dev/null || true
else git clone -q --bare --filter=blob:none https://github.com/omacom/omarchy "$repo" 2>/dev/null || true; fi
from=""; [[ $oraw =~ \.g([0-9a-f]{7,}) ]] && command git -C "$repo" cat-file -e "${BASH_REMATCH[1]}" 2>/dev/null && from=${BASH_REMATCH[1]}
[[ -z $from && -n $oi ]] && command git -C "$repo" rev-parse -q --verify "v$oi" >/dev/null && from="v$oi"
latest=$(command git -C "$repo" tag -l 'v*' 2>/dev/null | sort -V | tail -1)
range="${from:+$from..}origin/HEAD"; command git -C "$repo" rev-parse -q --verify origin/HEAD >/dev/null 2>&1 || range="${from:+$from..}HEAD"
log=$(command git -C "$repo" log --format='%h %s' "$range" 2>/dev/null | head -400 || true)
ncommits=$(grep -c . <<<"$log" || true)
hits=$(grep -iE "$KW" <<<"$log" | cut -c1-200 | head -40 || true)
results+=("$(jq -nc --arg i "$oraw" --arg f "$from" --arg l "$latest" --argjson n "${ncommits:-0}" --arg h "$hits" \
  '{name:"omarchy",installed:$i,source:"git log (tags, no releases)",since:$f,latest_tag:$l,new_commits:$n,hits:($h|split("\n")|map(select(length>0)))}')")
out=$(printf '%s\n' "${results[@]}" | jq -sc --arg kw "$KW" '{checked_at:(now|todate),keywords:$kw,items:.,attention:[.[]|select((.hits|length)>0)|.name]}')
if ((json_only)); then echo "$out"; else
  echo "$out" | jq -r '.items[]|"== \(.name) (installed \(.installed // "-"); \(if .new_versions then "new: \(.new_versions|join(", "))" else "\(.new_commits) new commits since \(.since // "?"), latest tag \(.latest_tag)" end))\n" + (if (.hits|length)==0 then "  no keyword hits" else (.hits|map("  - "+.)|join("\n")) end)'
  echo; echo "$out" | jq -r '"Needs attention: \(.attention|join(", ") | if .=="" then "none" else . end)"'
fi
