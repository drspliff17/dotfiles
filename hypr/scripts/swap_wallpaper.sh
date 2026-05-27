#!/usr/bin/env bash

WALLPAPER=""
FAV_MODE=0
case "$1" in
-f | fav)
  FAV_MODE=1
  shift
  ;;
esac

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

[[ -z "$WALLPAPER" ]] && {
  if [[ "$FAV_MODE" -eq 0 ]]; then
    WALLPAPER="$(/usr/local/bin/theme_selector -o random)"
  else
    WALLPAPER="$(/usr/local/bin/theme_selector -o random -f)"
  fi
}
/usr/bin/waypaper --wallpaper "$WALLPAPER" >/dev/null

/usr/bin/wal -i "$WALLPAPER" >/dev/null 2>&1
bash /home/drspliff/.config/hypr/scripts/update_colours.sh
