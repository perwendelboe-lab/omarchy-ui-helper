#!/usr/bin/env bash
set -euo pipefail
. "$(dirname "$0")/lib.sh"
c=$(cursor)
jq -n --argjson m "$(hyprctl monitors -j)" --argjson a "$(hyprctl activewindow -j 2>/dev/null || echo null)" \
  --argjson cl "$(hyprctl clients -j)" --argjson x "${c%,*}" --argjson y "${c#*,}" '
 {coords:"logical (layout) pixels; physical = (logical - monitor.x/y) * scale",
  cursor:{x:$x,y:$y},
  monitors:[$m[]|{name,id,x,y,width,height,scale,logical:{w:(.width/.scale|floor),h:(.height/.scale|floor)},transform,focused,activeWorkspace:.activeWorkspace.name}],
  active:($a|if .==null or .=={} then null else {address,class,title,at,size,workspace:.workspace.name} end),
  clients:[$cl[]|{address,class,title,at,size,workspace:.workspace.name,floating,fullscreen}]}'
