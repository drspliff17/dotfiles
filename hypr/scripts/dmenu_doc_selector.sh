#!/usr/bin/env bash

root="$HOME/doc"
selectionIsFile=false
selection="$(ls "$root" | dmenu -c -vi -l 30)"
[[ -z "$selection" ]] && exit 1
[[ -f "$root/$selection" ]] && selectionIsFile=true || root="$root/$selection"

[[ "$root" = "$HOME/doc/hyprland-wiki" ]] && root="$HOME/doc/hyprland-wiki/content"

while ! $selectionIsFile; do
  if [[ -d "$root" ]]; then
    selection="$(ls "$root" | dmenu -c -vi -l 30)"
    [[ -z "$selection" ]] && exit 1
    root="$root/$selection"
  else
    selectionIsFile=true
  fi
done

[[ -f "$root" ]] && {
  sock="/tmp/nvim-$(date +%s%N)-docselector.sock"
  kitty nvim --listen "$sock" -R "$root" && exit 0
}
exit 1
