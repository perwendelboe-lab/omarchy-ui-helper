#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
q=${1:?usage: ocr-find.sh TEXT}
have tesseract || die "tesseract missing: sudo pacman -S tesseract tesseract-data-eng" 5
img=$("$(dirname "$0")/shot.sh" full)
read -r scale mx my < <(hyprctl monitors -j | jq -r '.[]|select(.focused)|"\(.scale) \(.x) \(.y)"')
# grim on a single monitor captures physical px; convert to logical
tesseract "$img" - --psm 11 tsv 2>/dev/null | awk -F'\t' -v q="$q" -v s="$scale" -v mx="$mx" -v my="$my" '
  BEGIN{IGNORECASE=1} NR>1 && $12!="" && index(tolower($12),tolower(q)) {
   printf "{\"text\":\"%s\",\"conf\":%s,\"x\":%d,\"y\":%d,\"w\":%d,\"h\":%d}\n",$12,$11,mx+($7+$9/2)/s,my+($8+$10/2)/s,$9/s,$10/s }' \
 | jq -sc --arg img "$img" '{ok:(length>0),image:$img,matches:.}'
