#!/usr/bin/env bash

#TODO: Create help message
# Create extended functionality and Eventually integrate into themectl

LIB_NOTIFY="$HOME/.config/bash/lib/notify.sh"
source "$LIB_NOTIFY" || {
  notify-send -a center-text -t 1500 -u normal "Error" "Could not source required lib: $LIB_NOTIFY"
  exit 1
}

pgrep nsxiv && pkill nsxiv

### Helper functions

## Checks/Validation
_filenameInCache() {
  local file="$1"
  [[ -f "$GIF_CACHE_DIR/$file" ]] && return 0
  return 1
}

## $FAV_DB integration logic
_favExists() {
  yq -e ".wallpapers[] | select(. == \"$1\")" "$FAV_DB" >/dev/null 2>&1
}

_addFav() {
  local path="$1"
  _favExists "$path" && return 0
  yq -i ".wallpapers += [\"$path\"]" "$FAV_DB"
  _notify -a ct "Added to favourites: $(basename "$path")"
}

_removeFav() {
  local path="$1"
  yq -i "del(.wallpapers[] | select(. == \"$path\"))" "$FAV_DB"
  _notify -a ct "Removed from favourites: $(basename "$path")"
}

_loadFavs() {
  FILES=()
  [[ ! -f "$FAV_DB" ]] && _notify -a ct -e "Favourites file not found: $FAV_DB" && return 1
  mapfile -t FILES < <(yq -r '.wallpapers[]' "$FAV_DB")
  [[ "${#FILES[@]}" -eq 0 ]] && _notify -a ct "No entires in favourites file" && return 1
  return 0
}

_clearFavs() {
  rm "$FAV_DB"
  cat <<EOF >"$FAV_DB"
wallpapers: []
EOF
  _notify -a ct "Cleared Favourites!"
}

## Main logic

_handleOutput() {
  local file="$1"
  case "$OUTPUT" in
  0) sw "$file" 2>&1 >/dev/null ;;
  1) echo "$file" ;;
  esac
}

# Remove all pngs inside of $GIF_CACHE_DIR and clear nsxiv cache
_clearGifCache() {
  rm -r "$GIF_CACHE_DIR"/* || {
    _notify -a ct "GIF Cache already empty"
    return 1
  }
  nsxiv --clean-cache
  _notify -a ct "Cleared GIF Cache"
  return 0
}

# Convert all gifs inside $GIF_DIR to png inside $GIF_CACHE_DIR
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
      ffmpeg -i "$f" -frames:v 1 "$GIF_CACHE_DIR/$cname" 2>&1 >/dev/null || {
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
  gifs=("$GIF_CACHE_DIR"/*)
  [[ "${#gifs[@]}" -eq 0 ]] && _updateGifCache
  [[ "$DO_PNG" -eq 1 ]] && FILES+=("${pngs[@]}")
  [[ "$DO_GIF" -eq 1 ]] && FILES+=("${gifs[@]}")
  shopt -u nullglob
}

# Open nsxiv, process selection, and call sw
_selectAndApply() {
  local selection="$(printf '%s\n' "${FILES[@]}" | nsxiv -to - | tr -d '\n')"
  [[ -z "$selection" ]] && exit 0
  selection="$(basename "$selection")"
  [[ ! -f "$PNG_DIR/$selection" ]] && {
    selection="${selection%.png}.gif"
    [[ ! -f "$GIF_DIR/$selection" ]] && _notify -a ct -e "Could not find $selection" && exit 1
    _handleOutput "$GIF_DIR/$selection"
    _notify -a ct "Set theme $selection"
    exit 0
  }
  _handleOutput "$PNG_DIR/$selection"
  _notify -a ct "Set theme $selection"
}

PNG_DIR="$HOME/Pictures/Selectable/image-wallpapers"
GIF_DIR="$HOME/Pictures/Selectable/Gif-wallpapers"
GIF_CACHE_DIR="$HOME/.cache/themectl/converted_to_png"
FAV_DB="$HOME/dev/data/favourite_wallpapers.yml"
FILES=()
MODE=""
VERBOSE=0
CLEAR=0
DO_PNG=0
DO_GIF=0
DO_RANDOM_ONLY_FAV=0
OUTPUT=0

mkdir -p "$GIF_DIR"
mkdir -p "$GIF_CACHE_DIR"

# Parse Args
while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -u | update)
    MODE="UPDATE"
    shift
    ;;
  -c | clear)
    CLEAR=1
    shift
    case "$1" in
    -g | gif)
      MODE="CLEAR_GIF"
      shift
      continue
      ;;
    -f | fav)
      MODE="CLEAR_FAV"
      shift
      continue
      ;;
    esac
    [[ -z "$MODE" ]] && _notify -a ct -e "Expected CLEAR mode: valid modes = [ gif fav ]" && exit 1
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
  -f | fav)
    MODE="FAV"
    shift
    case "$1" in
    a | add)
      MODE="FAV_ADD"
      shift
      ;;
    r | rm)
      MODE="FAV_REMOVE"
      shift
      ;;
    esac
    ;;
  -o | output)
    OUTPUT=1
    shift
    ;;
  -r | random)
    MODE="RANDOM"
    shift
    case "$1" in
    -f | fav)
      DO_RANDOM_ONLY_FAV=1
      shift
      ;;
    esac
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
[[ "$CLEAR" -eq 1 ]] && {
  case "$MODE" in
  CLEAR_GIF)
    _clearGifCache
    exit 0
    ;;
  CLEAR_FAV)
    _clearFavs
    exit 0
    ;;
  esac
}
case "$MODE" in
"UPDATE")
  _updateGifCache || exit 1
  exit 0
  ;;
"SELECT")
  _assembleOptions
  _selectAndApply || exit 1
  ;;
"FAV")
  _loadFavs || exit 1
  _selectAndApply
  ;;
"FAV_ADD")
  _assembleOptions || exit 1

  mapfile -t selection < <(printf '%s\n' "${FILES[@]}" | nsxiv -to -)

  [[ "${#selection[@]}" -eq 0 ]] && exit 0

  for s in "${selection[@]}"; do
    [[ -z "$s" ]] && continue
    _addFav "$s"
  done
  ;;
"FAV_REMOVE")
  _loadFavs || exit 1

  mapfile -t selection < <(printf '%s\n' "${FILES[@]}" | nsxiv -to -)

  [[ "${#selection[@]}" -eq 0 ]] && exit 0

  for s in "${selection[@]}"; do
    [[ -z "$s" ]] && continue
    _removeFav "$s"
  done
  ;;
"RANDOM")
  case "$DO_RANDOM_ONLY_FAV" in
  0)
    DO_PNG=1
    DO_GIF=1
    _assembleOptions
    ;;
  1) _loadFavs ;;
  esac
  mapfile -t rand < <(printf '%s\n' "${FILES[@]}" | shuf -n 1)
  [[ -z "${rand[*]}" ]] && exit 1
  selection="${rand[0]}"
  selection="$(basename "$selection")"
  [[ ! -f "$PNG_DIR/$selection" ]] && {
    selection="${selection%.png}.gif"
    [[ ! -f "$GIF_DIR/$selection" ]] && _notify -a ct -e "Could not find $selection" && exit 1
    _handleOutput "$GIF_DIR/$selection"
    _notify -a ct "Set theme $selection"
    exit 0
  }
  _handleOutput "$PNG_DIR/$selection"
  _notify -a ct "Set theme $selection"
  ;;
*)
  _notify -a ct -e "Invalid mode: $MODE" && exit 1
  ;;
esac
