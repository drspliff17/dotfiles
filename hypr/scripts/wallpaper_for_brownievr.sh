#!/usr/bin/env bash

# EDIT THIS TO CHANGE WHERE FILES ARE SELECTED FROM
WALLPAPER_LOCATION="$HOME/Pictures/Selectable/image-wallpapers"

# Brightness Mode, can be either [ dark / light ]
B_MODE="light"

# Helper functions

_printHelp() {
  cat <<EOF
Swap Wallpaper
==============
Default behaviour: Randomly pick a wallpaper from $WALLPAPER_LOCATION
Valid exts are [ .png, .jpg, .gif ]
Example:
swap_wallpaper.sh                             | Pick random wallpaper from given dir
swap_wallpaper.sh ~/Pictures/someImage.png    | Set given wallpaper
EOF
}

_set_and_generate_schemes() {
  waypaper --wallpaper "$1"
  wal -i "$1"
}

_pick_random_wallpaper() {
  local idx=$((RANDOM % COUNT))
  echo "${IMAGES[$idx]}"
}

# Set during script lifecycle, don't touch
MODE=""
WALLPAPER=""
COUNT=""

# Arg parsing
while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -h | --help | help)
    _printHelp
    exit 0
    ;;
  *)
    if [[ -f "$1" ]]; then
      MODE="set"
      WALLPAPER="$1"
      shift
    fi
    echo "Invalid Argument Given: $1 : Expected valid file path"
    shift
    ;;
  esac
done
[[ -z "$MODE" ]] && MODE="random"

# Get all valid images
shopt -s nullglob
IMAGES=("$WALLPAPER_LOCATION"/*.{png,jpg,gif})
shopt -u nullglob

COUNT="${#IMAGES[@]}"
[[ "$COUNT" -eq 0 ]] && notify-send -u normal -t 2500 "No wallpapers found in: $WALLPAPER_LOCATION" && exit 0

# Main execution, set wallpaper && generate colour scheme from it
case "$MODE" in
set)
  [[ ! -f "$WALLPAPER" ]] && notify-send -u critical -t 5000 "Given wallpaper file not found: $WALLPAPER"
  _set_and_generate_schemes "$WALLPAPER"
  notify-send -u low -t 1600 "Set theme: $WALLPAPER"
  ;;

random)
  WALLPAPER="$(_pick_random_wallpaper)"
  _set_and_generate_schemes "$WALLPAPER"
  notify-send -u low -t 1600 "Set theme: $WALLPAPER"
  ;;
esac

# Call external script to actually use the newly cached colour schemes, and integreate with external programs
[[ ! -f "$HOME/.config/hypr/scripts/change-colours.sh" ]] && notify-send -u critical -t 5000 "Required file not found: $HOME/.config/hypr/scripts/change-colours.sh" && exit 1
bash $HOME/.config/hypr/scripts/change-colours.sh "$WALLPAPER" "$B_MODE"
