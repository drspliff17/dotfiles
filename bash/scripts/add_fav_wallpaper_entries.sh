#!/usr/bin/env bash

db="$HOME/dev/data/favourite_wallpapers.yml"
[[ ! -f "$db" ]] && echo "Expected file does not exist: $db" >&2 && exit 1
[[ -z "$1" ]] && echo "Expected atleast one image path to append to fav wallpaper db" >&2 && exit 1

for p in "$@"; do
  [[ ! -f "$p" ]] && echo "Skipping Invalid Path: $p" >&2 && continue
  yq -i ".wallpapers += [\"$p\"]" "$db" && echo "Added To Favourites: $(basename "$p")"
done
