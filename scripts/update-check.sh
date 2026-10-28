#!/usr/bin/env bash
set -euo pipefail
# update-check.sh [--json] [--apply]
# Installed vs latest for cua-driver, Omarchy, Hyprland, wlrctl, ydotool, Grok Bot desktop app, hypr-hands.
# Uses `git ls-remote` for upstream tags (no GitHub API rate limit). Read-only unless --apply
# (which only runs the official, sudo-free `cua-driver update --apply`).
. "$(dirname "$0")/lib.sh"
ROOT=$(cd "$(dirname "$0")/.." && pwd)
json_only=0 apply=0
for a in "$@"; do case $a in --json) json_only=1;; --apply) apply=1;; -h|--help) sed -n 2,5p "$0"; exit 0;; esac; done

latest_tag(){ # repo prefix -> highest semver tag (stable only)
  git ls-remote --tags --refs "https://github.com/$1" 2>/dev/null | awk -F/ '{print $3}' \
    | grep -E "^$2[0-9]+\.[0-9]+\.[0-9]+$" | sed "s/^$2//" | sort -V | tail -1; }
semver(){ grep -oE '[0-9]+\.[0-9]+\.[0-9]+' <<<"${1:-}" | head -1 || true; }
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
pkg_latest(){ # official pacman repo version only (the AUR is deliberately never consulted or suggested)
  local v; v=$(LC_ALL=C pacman -Si "$1" 2>/dev/null | awk -F': ' '/^Version/{print $2; exit}')
  [[ -n $v ]] && echo "repo $v"; return 0; }
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
ol=$(latest_tag omacom/omarchy v); os=$(cmp "$oi" "$ol")
onote="installed '$oraw' (package ${opkg:-?}); update: omarchy update"
osrc="github.com/omacom/omarchy tags"
if [[ $opkg == omarchy-dev && $oraw =~ \.g([0-9a-f]{7,}) ]]; then
  # dev channel builds a git commit of the default branch: compare commits, not tags
  oc=${BASH_REMATCH[1]}; oh=$(git ls-remote https://github.com/omacom/omarchy HEAD 2>/dev/null | cut -c1-${#oc})
  osrc="github.com/omacom/omarchy HEAD (dev channel)"; onote+="; dev channel at commit $oc, upstream HEAD ${oh:-?}; latest stable tag v$ol"
  [[ -n $oh ]] && { [[ $oh == "$oc" ]] && os=up-to-date || os=update-available; } || os=unknown
  oi="$oi+$oc"; ol="${oh:+HEAD@$oh}"
fi
if [[ $opkg == omarchy && $oraw =~ ^([0-9]+\.[0-9]+\.[0-9]+)rc([0-9]+) ]]; then
  # rc channel: pacman version 4.5.0rc2-1 <-> tag v4.5.0-rc2; compare against the newest rc or stable tag
  orc="${BASH_REMATCH[1]}-rc${BASH_REMATCH[2]}"
  olr=$(git ls-remote --tags --refs https://github.com/omacom/omarchy 2>/dev/null | awk -F/ '{print $3}' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?$' | sed 's/^v//; s/-rc/~rc/' | sort -V | sed 's/~rc/-rc/' | tail -1)
  oi=$orc; ol=${olr:-$ol}; osrc="github.com/omacom/omarchy tags (rc channel)"; onote+="; rc channel"
  if [[ -z $olr ]]; then os=unknown; elif [[ $olr == "$orc" ]]; then os=up-to-date; else os=update-available; fi
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
  if [[ $p == wlrctl ]]; then  # AUR-only: report it only if the user already has it, never suggest installing it
    [[ -z $pi ]] && continue
    add "$p" "$pi" "" unknown false "installed outside the official repos" "AUR-only; optional. Not offered by hypr-hands. Cua Driver or ydotool replace it"; continue
  fi
  st=$(cmp "$(semver "$pi")" "$(semver "${pl#* }")"); [[ -n $pi && $pi == "${pl#* }" ]] && st=up-to-date
  add "$p" "$pi" "${pl#* }" "$st" false "${pl%% *}" "sudo pacman -S $p"
done
# Grok Bot desktop app (package grok-bot from Omarchy's repo; an AUR repack is detected only to warn about it)
gp=$(pacman -Qq grok-bot grok-bot-desktop grok-bot-bin grokbot-linux-port-bin 2>/dev/null | head -1 || true)
if [[ -n $gp ]]; then gi=$(pacman -Q "$gp" | awk '{print $2}'); gl=$(pkg_latest "$gp" || true)
  gaur=""; [[ $gp != grok-bot ]] && gaur=1; [[ -z $gl ]] && gl="repo $(pkg_latest grok-bot | awk '{print $2}')"
  gs=$(cmp "$(semver "$gi")" "$(semver "${gl#* }")"); [[ $gi == "${gl#* }" ]] && gs=up-to-date
  # Upstream truth: the Linux update feed the app itself follows (Omarchy's hourly sync reads the same feed).
  # pacman -Si only reflects the local sync DB, which is stale until the next `pacman -Sy`/omarchy update.
  ga=$([[ $(uname -m) == aarch64 ]] && echo arm64 || echo x64)
  nil=$(printf '%08d-%04d-%04d-%04d-%012d' 0 0 0 0 0)  # all-zero placeholder id the feed expects (built here so it is not mistaken for a real UUID)
  gf=$(curl -fsS --max-time 15 "https://api2.cursor.sh/updates/api/update/linux-$ga/sand/0.0.0/$nil/stable" 2>/dev/null | jq -r '.version // empty' || true)
  gfs=$(cmp "$(semver "$gi")" "$gf")
  [[ $gfs == update-available && $gs != update-available ]] && gs=update-available
  add grok-bot "$gi" "${gf:-${gl#* }}" "$gs" false "feed $ga; ${gl%% *} $gp ${gl#* }" "$( [[ -n $gaur ]] && echo "$gp is not from Omarchy's official repo (likely the AUR). Replace it with the official package: sudo pacman -Rns $gp && omarchy-pkg-add grok-bot" || echo "sudo pacman -Syu $gp (or omarchy update); if the repo lags the feed, wait ~1h for Omarchy's sync")"
else add grok-bot "" "" not-installed false "-" "not installed; see: hypr-hands grokbot install-help"; fi
# hypr-hands: installed copy (~/.local/share/hypr-hands/.source) or git clone, vs GitHub main
UPSTREAM=${HYPR_HANDS_REPO:-https://github.com/perwendelboe-lab/omarchy-ui-helper}
hv=$(jq -r .version "$ROOT/plugin.json"); clone=""
for c in "$ROOT" "$HOME/code/omarchy-ui-helper" "$HOME/code/hypr-hands"; do [[ -d $c/.git ]] && { clone=$c; break; }; done
if [[ -n $clone ]]; then hh=$(command git -C "$clone" rev-parse --short HEAD); where="clone $clone"
else hh=$(awk '{print $2}' "$ROOT/.source" 2>/dev/null || true); where="install $ROOT"; fi
uh=$(command git ls-remote "$UPSTREAM" refs/heads/main 2>/dev/null | cut -c1-7)
uv=$(curl -fsSL "${UPSTREAM/github.com/raw.githubusercontent.com}/main/plugin.json" 2>/dev/null | jq -r '.version // empty' || true)
if [[ -z $uh ]]; then hst=unknown; elif [[ ${hh:0:7} == "$uh" ]]; then hst=up-to-date; else hst=update-available; fi
add hypr-hands "$hv@${hh:-?}" "${uv:-?}@${uh:-?}" "$hst" "$(major "$hv" "${uv:-$hv}")" "$UPSTREAM" "checked via $where; update: git -C ~/code/omarchy-ui-helper pull && ~/code/omarchy-ui-helper/install.sh --yes --no-packages"
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
