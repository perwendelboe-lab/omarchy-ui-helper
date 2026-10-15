#!/usr/bin/env bash
# Pre-commit privacy check: greps staged (or all tracked, with --all) files for personal data.
# Extra private patterns (your email, hostname, machine IDs) go one-per-line (ERE) in
# ${XDG_CONFIG_HOME:-~/.config}/hypr-hands/privacy-patterns, which stays outside the repo.
# Install as hook: ln -sf ../../scripts/privacy-check.sh .git/hooks/pre-commit
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
pats=(
  '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'          # email addresses
  '/home/[a-z_][a-z0-9_-]*/'                                # home paths
  '([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}'                      # MAC
  '\b(10|127|192\.168|172\.(1[6-9]|2[0-9]|3[01]))(\.[0-9]{1,3}){2,3}\b' # private IPs
  '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' # UUIDs (machine/agent/store IDs)
  'gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|xox[abpr]-[0-9A-Za-z-]+|AKIA[0-9A-Z]{16}'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
)
extra=${XDG_CONFIG_HOME:-$HOME/.config}/hypr-hands/privacy-patterns
[[ -f $extra ]] && while IFS= read -r l; do [[ -n $l && $l != \#* ]] && pats+=("$l"); done <"$extra"
if [[ ${1:-} == --all ]]; then mapfile -t files < <(git ls-files); else mapfile -t files < <(git diff --cached --name-only --diff-filter=ACM); fi
fail=0
for f in "${files[@]}"; do
  [[ $f == scripts/privacy-check.sh || ! -f $f ]] && continue
  case $f in *.env|.env*|*.log|*.pem|*.key) echo "privacy-check: forbidden file type: $f"; fail=1; continue;; esac
  [[ $f == *.png && $f != assets/logo.png ]] && { echo "privacy-check: image outside assets/: $f"; fail=1; continue; }
  for p in "${pats[@]}"; do
    # allow noreply addresses and example domains
    if hits=$(grep -nIE -- "$p" "$f" | grep -vE 'noreply|example\.(com|org)|users\.noreply'); then
      echo "privacy-check: $f matches /$p/:"; echo "$hits" | cut -c1-160; fail=1
    fi
  done
done
((fail)) && { echo "privacy-check: FAILED (fix, or commit with --no-verify if a false positive)"; exit 1; }
echo "privacy-check: ok (${#files[@]} files)"
