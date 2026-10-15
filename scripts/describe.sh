#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
c=$(cursor)
echo "locked: $(locked && echo yes || echo no)"
hyprctl monitors -j | jq -r '.[]|"monitor \(.name): \(.width)x\(.height)@\(.scale) at \(.x),\(.y) ws=\(.activeWorkspace.name)\(if .focused then " (focused)" else "" end)"'
hyprctl activewindow -j | jq -r 'if .class then "active: [\(.class)] \(.title) ws=\(.workspace.name)" else "active: none" end'
echo "cursor: $c"
hyprctl clients -j | jq -r 'group_by(.workspace.name)[]|"ws \(.[0].workspace.name): " + ([.[]|"\(.class)"]|join(", "))'
