#!/usr/bin/env bash

target_ws="$1"
source_ws=$(hyprctl activeworkspace -j | jq -r '.id')

hyprctl clients -j | jq -r "
  .[]
  | select(.workspace.id == $source_ws)
  | .address
" | while read -r addr; do

  hyprctl dispatch "hl.dsp.window.move({
    workspace = \"$target_ws\",
    window = \"address:$addr\",
    follow = false
  })"

done
