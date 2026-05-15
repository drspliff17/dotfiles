#!/usr/bin/env bash
# Refactored dmenu_music_selector.sh, using Wofi

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

mode="${1:-files}"

# Root of search, when not using $cacheFile
musicPath="$HOME/Music/Songs"

# Populated with new-line entries: FileName|FullFilePath
cacheFile="$HOME/.cache/dmenu_music_selector"

# Dynamically assigned from wofi
selectedArtist=""
selectedFile=""
selectedName=""

WOFI_WIDTH="25%"
WOFI_HEIGHT="50%"

w_args=()

# Updates $cacheFile with new-line entries
_updateMusicSelectorCache() {
  [[ -f "$cacheFile" ]] && rm "$cacheFile"
  : >"$cacheFile"

  for artistDir in "$musicPath"/*; do
    [[ -d "$artistDir" ]] || continue
    for song in "$artistDir"/*.mp3; do
      [[ -f "$song" ]] || continue

      base display
      base="$(basename "$song" .mp3)"
      printf "%s|%s\n" "$base" "$song" >>"$cacheFile"
    done
  done
}

# Generate wofi using $cacheFile (Sets selectedFile)
_menuFromCache() {
  cacheFile="$HOME/.cache/dmenu_music_selector"
  [[ -f "$cacheFile" ]] || _updateMusicSelectorCache
  local selection fullpath

  WOFI_PROMPT="Cached Music"
  _construct w_args
  selection="$(
    awk -F'|' -v base="$musicPath" '{
    title=$1
    path=$2

    artist=path
    sub("^" base "/","", artist)
    sub("/[^/]+$","", artist)

    gsub("_"," ",title)
    gsub("_"," ",artist)

    printf "%s - %s\n", artist, title
    }' "$cacheFile" | wofi -d "${w_args[@]}"
  )" || exit 1

  selectedName="$selection"
  title="$(echo "$selection" | sed 's/.* - //' | sed 's/ /_/g')"
  artist="$(echo "$selection" | sed 's/ - .*//' | sed 's/ /_/g')"

  fullpath="$(
    awk -F'|' -v t="$title" -v a="$artist" -v base="$musicPath" '
  {
    path=$2
    art=path
    sub("^" base "/","", art)
    sub("/[^/]+$","", art)

    if ($1 == t && art == a) {
      print path
      exit
    }
  }' "$cacheFile"
  )"

  [[ -z "$fullpath" ]] && _notify -a ct -u normal -e "Invalid Selection" && exit 1
  selectedFile="$fullpath"
  return 0
}

# Generate wofi from $musicPath (Set selectedArtist)
_menuArtistSelection() {
  WOFI_PROMPT="Select Artist"
  _construct w_args
  selectedArtist="$(/usr/bin/ls "$musicPath" | sed 's/_/ /g' | wofi -d "${w_args[@]}")"
  [[ -z "$selectedArtist" ]] && return 1
  WOFI_PROMPT="$selectedArtist"
  selectedArtist="$(echo $selectedArtist | sed 's/ /_/g')"

  [[ ! -d "$musicPath/$selectedArtist" ]] && _notify -a ct -u normal -e "Invalid Artist" && exit 1
  return 0
}

# Generate wofi from $musicPath/$selectedArtist (Sets selectedFile)
_menuArtistFileSelection() {
  [[ -z "$selectedArtist" ]] && return 1
  _construct w_args
  selectedFile="$(/usr/bin/ls "$musicPath/$selectedArtist" | sed 's/_/ /g' | sed 's/\.[^.]*$//' | wofi -d "${w_args[@]}")"
  [[ -z "$selectedFile" ]] && exit 1
  selectedArtist="$(echo "$selectedArtist" | sed 's/_/ /g')"
  selectedName="$selectedArtist - $selectedFile"

  selectedArtist="$(echo "$selectedArtist" | sed 's/ /_/g')"
  selectedFile="$(echo $selectedFile | sed 's/ /_/g').mp3"
  [[ ! -f "$musicPath/$selectedArtist/$selectedFile" ]] && _notify -a ct -u normal -e "Invalid Song" && exit 1
  return 0
}

# Main
case "$mode" in
artist | files)
  if ! pgrep cmus; then
    kitty fish -c cmus &
    exit 0
  fi
  ;;
esac

case "$mode" in
artist)
  _menuArtistSelection
  _menuArtistFileSelection
  [[ -z "$selectedArtist" || -z "$selectedFile" ]] && exit 1
  cmus-remote -f "$musicPath/$selectedArtist/$selectedFile" && _notify -a ct -t 2000 "Now Playing: $selectedName"
  exit 0
  ;;

files)
  _menuFromCache
  [[ -z "$selectedFile" ]] && exit 1
  cmus-remote -f "$selectedFile" && _notify -a ct -t 2000 "Now Playing: $selectedName"
  exit 0
  ;;

update)
  if pgrep cmus; then
    cmus-remote -C 'add Music'
    cmus-remote -C 'update-cache'
  fi
  _notify -a ct "Starting Cache Update..." && _updateMusicSelectorCache && _notify -a ct "Cache Updated: $cacheFile"
  exit 0
  ;;

*)
  # _notify center-text urgent "[ERROR] wofi_music_selector.sh" " Invalid mode! Valid = [ artist files update ] | Got: $mode "
  _notify -a ct -u urgent "[ERROR] wofi_music_selector.sh" " Invalid mode! Valid = [ artist files update ] | Got: $mode "
  exit 1
  ;;
esac
