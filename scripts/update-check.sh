#!/usr/bin/env bash
set -euo pipefail
# update-check.sh [--json] [--apply]
# Installed vs latest for cua-driver, Omarchy, Hyprland, wlrctl, ydotool, hypr-hands.
# Uses `git ls-remote` for upstream tags (no GitHub API rate limit). Read-only unless --apply
# (which only runs the official, sudo-free `cua-driver update --apply`).
. "$(dirname "$0")/lib.sh"
ROOT=$(cd "$(dirname "$0")/.." && pwd)
json_only=0 apply=0
for a in "$@"; do case $a in --json) json_only=1;; --apply) apply=1;; -h|--help) sed -n 2,5p "$0"; exit 0;; esac; done

latest_tag(){ # repo prefix -> highest semver tag (stable only)
  git ls-remote --tags --refs "https://github.com/$1" 2>/dev/null | awk -F/ '{print $3}' \
    | grep -E "^$2[0-9]+\.[0-9]+\.[0-9]+$" | sed "s/^$2//" | sort -V | tail -1; }
semver(){ grep -oE '[0-9]+\.[0-9]+\.[0-9]+' <<<"${1:-}" | head -1; }
cmp(){ # installed latest -> status
  local i=$1 l=$2
  [[ -z $i ]] && { echo not-installed; return; }; [[ -z $l ]] && { echo unknown; return; }
  [[ $i == "$l" ]] && { echo up-to-date; return; }
  [[ $(printf '%s\n%s\n' "$i" "$l" | sort -V | tail -1) == "$i" ]] && { echo ahead; return; }
  echo update-available; }
major(){ # 1 if major bump (for 0.x: minor bump counts as major)
  local i=$1 l=$2; [[ -z $i || -z $l ]] && { echo false; return; }
  IFS=. read -r a b _ <<<"$i"; IFS=. read -r c d _ <<<"$l"
  if (( a==0 && c==0 )); then ((d>b)) && echo true || echo false; else ((c>a)) && echo true || echo false; fi; }
pkg_latest(){ # pacman repo version, else AUR
  local v; v=$(LC_ALL=C pacman -Si "$1" 2>/dev/null | awk -F': ' '/^Version/{print $2; exit}')
  if [[ -n $v ]]; then echo "repo $v"; return; fi
  v=$(curl -fsS "https://aur.archlinux.org/rpc/v5/info?arg[]=$1" 2>/dev/null | jq -r '.results[0].Version // empty')
  [[ -n $v ]] && echo "aur $v"; }
items=()
add(){ items+=("$(jq -nc --arg n "$1" --arg i "$2" --arg l "$3" --arg s "$4" --argjson m "$5" --arg src "$6" --arg note "$7" \
  '{name:$n,installed:$i,latest:$l,status:$s,major_bump:$m,source:$src,note:$note}')"); }

# cua-driver
ci=""; cbin=$(command -v cua-driver || echo "$HOME/.local/bin/cua-driver"); [[ -x $cbin ]] && ci=$(semver "$("$cbin" --version 2>/dev/null)")
cl=$(latest_tag trycua/cua cua-driver-rs-v); cs=$(cmp "$ci" "$cl")
add cua-driver "$ci" "$cl" "$cs" "$(major "$ci" "$cl")" "github.com/trycua/cua tags cua-driver-rs-v*" "update: cua-driver update --apply (or re-run https://cua.ai/driver/install.sh); then systemctl --user restart cua-driver.service"
# Omarchy
oraw=$(omarchy version 2>/dev/null || cat /usr/share/omarchy/version 2>/dev/null || true); oi=$(semver "$oraw")
opkg=$(pacman -Qq omarchy omarchy-dev 2>/dev/null | head -1 || true)
ol=$(latest_tag basecamp/omarchy v); os=$(cmp "$oi" "$ol")
onote="installed '$oraw' (package ${opkg:-?}); update: omarchy update"
osrc="github.com/basecamp/omarchy tags"
if [[ $opkg == omarchy-dev && $oraw =~ \.g([0-9a-f]{7,}) ]]; then
  # dev channel builds a git commit of the default branch: compare commits, not tags
  oc=${BASH_REMATCH[1]}; oh=$(git ls-remote https://github.com/basecamp/omarchy HEAD 2>/dev/null | cut -c1-${#oc})
  osrc="github.com/basecamp/omarchy HEAD (dev channel)"; onote+="; dev channel at commit $oc, upstream HEAD ${oh:-?}; latest stable tag v$ol"
  [[ -n $oh ]] && { [[ $oh == "$oc" ]] && os=up-to-date || os=update-available; } || os=unknown
  oi="$oi+$oc"; ol="${oh:+HEAD@$oh}"
fi
add omarchy "$oi" "$ol" "$os" "$(major "$(semver "$oi")" "$(semver "$ol")")" "$osrc" "$onote"
# Hyprland
hi=$(semver "$(hyprctl version 2>/dev/null | grep -m1 -oE 'Tag: v[0-9.]+' || true)"); [[ -z $hi ]] && hi=$(semver "$(pacman -Q hyprland 2>/dev/null || true)")
hl_=$(latest_tag hyprwm/Hyprland v); hs=$(cmp "$hi" "$hl_")
hpkg=$(pacman -Q hyprland 2>/dev/null | awk '{print $2}' || true); hrepo=$(pkg_latest hyprland || true)
add hyprland "$hi" "$hl_" "$hs" "$(major "$hi" "$hl_")" "github.com/hyprwm/Hyprland tags" "pacman ${hpkg:-?}, repo ${hrepo:-?}; update via omarchy update"
# wlrctl / ydotool (packages)
for p in wlrctl ydotool; do
  pi=$(pacman -Q "$p" 2>/dev/null | awk '{print $2}' || true); pl=$(pkg_latest "$p" || true)
  st=$(cmp "$(semver "$pi")" "$(semver "${pl#* }")"); [[ -n $pi && $pi == "${pl#* }" ]] && st=up-to-date
  add "$p" "$pi" "${pl#* }" "$st" false "${pl%% *}" "$( [[ ${pl%% *} == aur ]] && echo "yay -S aur/$p" || echo "sudo pacman -S $p")"
done
# hypr-hands
hv=$(jq -r .version "$ROOT/plugin.json"); hh=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || true)
dirty=$(git -C "$ROOT" status --porcelain 2>/dev/null | wc -l); remote=$(git -C "$ROOT" remote get-url origin 2>/dev/null || true)
hl2=""; hst=no-remote
if [[ -n $remote ]]; then hl2=$(git ls-remote "$remote" HEAD 2>/dev/null | cut -c1-7); [[ ${hl2:0:7} == "${hh:0:7}" ]] && hst=up-to-date || hst=update-available; fi
add hypr-hands "$hv@$hh" "$hl2" "$hst" false "${remote:-local}" "uncommitted files: $dirty"

out=$(printf '%s\n' "${items[@]}" | jq -sc '{checked_at:(now|todate),items:.,updates:[.[]|select(.status=="update-available")|.name],major_bumps:[.[]|select(.major_bump)|.name]}')
if ((json_only)); then echo "$out"; else
  echo "$out" | jq .
  echo; echo "== Summary"
  echo "$out" | jq -r '.items[]|"\(.name): \(.installed // "-") -> \(.latest // "?") [\(.status)]\(if .major_bump then " MAJOR" else "" end)"'
fi
if ((apply)); then
  if [[ $cs == update-available ]]; then echo "== Applying cua-driver update (official installer, no sudo)"; "$cbin" update --apply
    echo "Now run: systemctl --user restart cua-driver.service && cua-driver doctor"
  else echo "cua-driver: nothing to apply ($cs)"; fi
  echo "Other components are never updated by this script. Omarchy/Hyprland: omarchy update; packages: see notes."
fi
