#!/usr/bin/env bash

proot="$HOME/doc"
root="$proot"
selectionIsFile=false
selection="$(ls "$root" | dmenu -c -vi -l 30)"
[[ -z "$selection" ]] && exit 1
[[ -f "$root/$selection" ]] && selectionIsFile=true || root="$root/$selection"

while ! $selectionIsFile; do
  if [[ -d "$root" ]]; then

    # Exceptions
    case "$root" in
    "$proot/hyprland-wiki")
      root="$root/content"
      ;;
    esac

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
