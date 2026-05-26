#!/usr/bin/env bash

WALLPAPER=""
[[ -n "$1" ]] && {
  LIB_NOTIFY="$HOME/.config/bash/lib/notify.sh"
  source "$LIB_NOTIFY" || {
    notify-send -a center-text -t 1500 -u normal "Error" "Could not source required lib: $LIB_NOTIFY"
    exit 1
  }
  [[ ! -f "$1" ]] && _notify -a ct -e "Given wallpaper source could not be found: $1" && exit 1
  ALLOWED_EXT=("png" "gif")
  for ext in "${ALLOWED_EXT[@]}"; do
    [[ "$1" == *."$ext" ]] && WALLPAPER="$1"
  done
  [[ -z "$WALLPAPER" ]] && _notify -a ct -e "Given wallpaper source is an invalid filetype. Supported: ${ALLOWED_EXT[*]}" && exit 1
}

if [[ -z "$WALLPAPER" ]]; then
  /usr/bin/waypaper --random >/dev/null
  WALLPAPER=$(waypaper --list | jq -r '.[] | .wallpaper')
else
  /usr/bin/waypaper --wallpaper "$WALLPAPER" >/dev/null
fi

/usr/bin/wal -i "$WALLPAPER" >/dev/null 2>&1
bash /home/drspliff/.config/hypr/scripts/update_colours.sh
