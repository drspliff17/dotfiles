#!/usr/bin/env bash

LIB_NOTIFY="$HOME/.config/bash/lib/notify.sh"
source "$LIB_NOTIFY" || {
  notify-send -a center-text -t 1500 -u normal "Error" "Could not source required lib: $LIB_NOTIFY"
  exit 1
}

LIB_WOFI="$HOME/.config/bash/lib/wofi_construct.sh"
source "$LIB_WOFI" || {
  _notify -a ct -e -u normal "Could not source required lib: $LIB_WOFI"
  exit 1
}

# Checks if given file name exists inside of $GIF_TO_PNG_CACHE_DIR
_filenameInCache() {
  [[ ! -f "$GIF_TO_PNG_CACHE_DIR/$1" ]] && return 1
  _notify -a ct "Cleared GIF -> PNG Cache"
  return 0
}

# Remove all pngs inside of $GIF_TO_PNG_CACHE_DIR and clear nsxiv cache
_clearGifCache() {
  rm -r "$GIF_TO_PNG_CACHE_DIR"/* || {
    _notify -a ct "GIF Cache already empty"
    return 1
  }
  nsxiv --clean-cache
  _notify -a ct "Cleared GIF Cache"
  return 0
}

_gif2Png() {
  local fname="$1"
  [[ -f "$fname" ]] && fname="$(basename "$fname")"
  shopt -s nullglob
  [[ "$fname" == *.png ]] && {
    echo "$GIF_DIR/${fname%.png}.gif"
    return 0
  }
  shopt -u nullglob
  echo "$PNG_DIR/$fname"
}

_png2gif() {
  local fname="$1"
  fname="${fname%.png}.gif"
  [[ ! -f "$fname" ]] && return 1
}

# Convert all gifs inside $GIF_DIR to png inside $GIF_TO_PNG_CACHE_DIR
_updateGifCache() {
  local fname cname
  shopt -s nullglob

  local gifs=("$GIF_DIR"/*.gif)
  [[ ${#gifs[@]} -eq 0 ]] && {
    [[ "$VERBOSE" -eq 1 ]] && _notify -a ct "[INFO] No GIFs found in $GIF_DIR, exiting cache update"
    shopt -u nullglob
    return 0
  }

  _notify -a ct "Beginning cache update"

  for f in "${gifs[@]}"; do
    fname="$(basename "$f")"
    cname="${fname%.gif}.png"
    if _filenameInCache "$cname"; then
      [[ "$VERBOSE" -eq 1 ]] && _notify -a ct "[INFO] Skipping cache processing for file: $fname - $cname already exists"
    else
      ffmpeg -i "$f" -frames:v 1 "$GIF_TO_PNG_CACHE_DIR/$cname" 2>&1 >/dev/null || {
        _notify -a ct -e "Failed to cache $fname"
      }
    fi
  done

  nsxiv --update-cache
  _notify -a ct "[FINISHED]"
  shopt -u nullglob
  return 0
}

# Grab all pngs and gifs
_assembleOptions() {
  local pngs gifs
  FILES=()
  shopt -s nullglob
  pngs=("$PNG_DIR"/*)
  gifs=("$GIF_TO_PNG_CACHE_DIR"/*)
  [[ "${#gifs[@]}" -eq 0 ]] && _updateGifCache
  [[ "$DO_PNG" -eq 1 ]] && FILES+=("${pngs[@]}")
  [[ "$DO_GIF" -eq 1 ]] && FILES+=("${gifs[@]}")
  # FILES=("${pngs[@]}" "${gifs[@]}")
  shopt -u nullglob
}

PNG_DIR="$HOME/Pictures/Selectable/image-wallpapers"
GIF_DIR="$HOME/Pictures/Selectable/Gif-wallpapers"
GIF_TO_PNG_CACHE_DIR="$HOME/.cache/themectl/converted_to_png"
FILES=()
MODE=""
VERBOSE=0
CLEAR=0
DO_PNG=0
DO_GIF=0

mkdir -p "$GIF_DIR"
mkdir -p "$GIF_TO_PNG_CACHE_DIR"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -u | update)
    MODE="UPDATE"
    shift
    ;;
  -c | clear)
    CLEAR=1
    shift
    ;;
  -w | wipe)
    _clearGifCache
    exit 0
    ;;
  -p | png)
    DO_PNG=1
    shift
    ;;
  -g | gif)
    DO_GIF=1
    shift
    ;;
  -*)
    _notify -a ct -e "Unknown option: $1" && exit 1
    ;;
  *)
    _notify -a ct -e "Unknown value: $1" && exit 1
    ;;
  esac
done
[[ -z "$MODE" ]] && MODE="SELECT"
[[ "$CLEAR" -eq 1 ]] && _clearGifCache

case "$MODE" in
"UPDATE")
  _updateGifCache || exit 1
  exit 0
  ;;
"SELECT")
  _assembleOptions
  selection="$(printf '%s\n' "${FILES[@]}" | nsxiv -to - | tr -d '\n')"
  [[ -z "$selection" ]] && exit 0
  selection="$(basename "$selection")"
  [[ ! -f "$PNG_DIR/$selection" ]] && {
    selection="${selection%.png}.gif"
    [[ ! -f "$GIF_DIR/$selection" ]] && _notify -a ct -e "Could not find $selection" && exit 1
    sw "$GIF_DIR/$selection" 2>&1 >/dev/null
    exit 0
  }
  sw "$PNG_DIR/$selection" 2>&1 >/dev/null
  _notify -a ct "Set theme $(basename "$selection")"
  exit 0
  ;;
*)
  _notify -a ct -e "Invalid mode: $MODE" && exit 1
  ;;
esac
