#!/usr/bin/env bash

# Refactored dmenu_music_selector.sh, using Wofi

#TODO: Cleanup

#
# Main switch statement control
mode="$1"
[[ -z "$mode" ]] && mode="files"

# Root of search, when not using $cacheFile
musicPath="$HOME/Music/Songs"

# Populated with new-line entries: FileName|FullFilePath
cacheFile="$HOME/.cache/dmenu_music_selector"

# Dynamically assigned from wofi
selectedArtist=""
selectedFile=""
selectedName=""

# Passed to wofi, for -c
w_prompt=""
w_width="25%"
w_height="50%"
w_columns=""
w_lines=""

w_args=()

# Build wofi arguments (w_args) from w_* variables
_constructArgs() {
  w_args=()

  w_args+=("--prompt" "$w_prompt")
  w_args+=("--width" "$w_width")
  w_args+=("--height" "$w_height")

  [[ -n $w_columns ]] && w_args+=("--columns" "$w_columns")
  [[ -n $w_lines ]] && w_args+=("--lines" "$w_lines")
}

# Simple Wrapper for shortening notify-send, args: appname  urgency  head  body
_notify() {
  local appname="$1"
  local urg="$2"
  local head="$3"
  local body="$4"
  notify-send -u "$urg" -t 2000 -a "$appname" "$head" "$body"
  return 0
}

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

  w_prompt="Cached Music"
  _constructArgs
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

  [[ -z "$fullpath" ]] && _notify center-text normal "Invalid Selection" && exit 1
  selectedFile="$fullpath"
  return 0
}

# Generate wofi from $musicPath (Set selectedArtist)
_menuArtistSelection() {
  w_prompt="Select Artist"
  _constructArgs
  selectedArtist="$(/usr/bin/ls "$musicPath" | sed 's/_/ /g' | wofi -d "${w_args[@]}")"
  [[ -z "$selectedArtist" ]] && return 1
  w_prompt="$selectedArtist"
  selectedArtist="$(echo $selectedArtist | sed 's/ /_/g')"

  [[ ! -d "$musicPath/$selectedArtist" ]] && _notify center-text normal "Invalid Artist" && exit 1
  return 0
}

# Generate wofi from $musicPath/$selectedArtist (Sets selectedFile)
_menuArtistFileSelection() {
  [[ -z "$selectedArtist" ]] && return 1
  _constructArgs
  selectedFile="$(/usr/bin/ls "$musicPath/$selectedArtist" | sed 's/_/ /g' | sed 's/\.[^.]*$//' | wofi -d "${w_args[@]}")"
  [[ -z "$selectedFile" ]] && exit 1
  selectedArtist="$(echo "$selectedArtist" | sed 's/_/ /g')"
  selectedName="$selectedArtist - $selectedFile"

  selectedArtist="$(echo "$selectedArtist" | sed 's/ /_/g')"
  selectedFile="$(echo $selectedFile | sed 's/ /_/g').mp3"
  [[ ! -f "$musicPath/$selectedArtist/$selectedFile" ]] && _notify center-text normal "Invalid Song" && exit 1
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
  cmus-remote -f "$musicPath/$selectedArtist/$selectedFile" && _notify center-text low "Now Playing: $selectedName"
  exit 0
  ;;

files)
  _menuFromCache
  [[ -z "$selectedFile" ]] && exit 1
  cmus-remote -f "$selectedFile" && _notify center-text low "Now Playing: $selectedName"
  exit 0
  ;;

update)
  if pgrep cmus; then
    cmus-remote -C 'add Music'
    cmus-remote -C 'update-cache'
  fi
  _notify center-text low "Starting Cache Update..." && _updateMusicSelectorCache && _notify center-text low "Cache Updated: $cacheFile"
  exit 0
  ;;

*)
  _notify center-text urgent "[ERROR] wofi_music_selector.sh" " Invalid mode! Valid = [ artist files update ] | Got: $mode "
  exit 1
  ;;
esac
