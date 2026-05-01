#!/usr/bin/env bash

# NOTE: MODIFY TO ACT LIKE DMENU_MUSIC_SELECTOR (CACHE DATA TO FILE FOR SPEED)

#TODO: Add update cache, need to store preview .pngs, path to said pngs, and path to
# source image

#NOTE: img=$(./.config/hypr/scripts/dmenu_theme_selector.sh | cut -d'/' -f4 | sed 's/.png/.gif/')
#      echo "$HOME/Pictures/Selectable/Gif-wallpapers/$img"

# mode="$1"
# [[ -z "$mode" ]] && mode="select"
#
# rootPath="$HOME/Pictures/Selectable"
# gifPath="$rootPath/Selectable/Gif-wallpapers"
#
prefix="PNG_IMAGE:"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

shopt -s nullglob

themePath="$HOME/.config/themectl/themes"
cacheFile="$HOME/.cache/dmenu_theme_selector"
# _updateThemeSelectorCache() {
#   [[ -f "$cacheFile" ]] && rm "$cacheFile"
#   : >"$cacheFile"
#
#   for themeFile in "$"
# }

files=("$HOME/Pictures/Selectable/Gif-wallpapers"/*.gif)

for file in "${files[@]}"; do
  base="$(basename "${file%.*}")"
  out="$tmpdir/$base.png"

  ffmpeg -y -i "$file" -vframes 1 -vf "scale=200:-1" "$out" >/dev/null 2>&1
done

for file in "$tmpdir"/*.png; do
  printf '%s%s\n' "$prefix$file"
done | dmenu -c -l 50 -is 400 -vi -g 4
