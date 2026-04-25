#!/usr/bin/env bash

target_ws="$1"

current_ws=$(hyprctl activeworkspace -j | jq -r '.id')

mapfile -t addrs < <(
  hyprctl clients -j | jq -r ".[] | select(.workspace.id == $current_ws) | .address"
)

cmd=""
for addr in "${addrs[@]}"; do
  cmd+="dispatch movetoworkspacesilent $target_ws,address:$addr;"
done

cmd+="dispatch workspace $target_ws"

hyprctl --batch "$cmd"
