#!/usr/bin/env bash

mode="$1"
[[ -z "$mode" ]] && mode="files"
musicPath="$HOME/Music/Songs"
selectedArtist=""
selectedFile=""
selectedName=""
lineCount=20
cacheFile="$HOME/.cache/dmenu_music_selector"

# Wrapper for notify-send
_notify() {
  appname="$1"
  urg="$2"
  head="$3"
  body="$4"
  notify-send -u "$urg" -t 2000 -a "$appname" "$head" "$body" && exit 0
}

# Updates $cacheFile (/creates)
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

# # Generate dmenu using $cacheFile (Set selectedFile)
# _menuFromCache() {
#   cacheFile="$HOME/.cache/dmenu_music_selector"
#   [[ -f "$cacheFile" ]] || _updateMusicSelectorCache
#   local selection fullpath
#
#   selection="$(cut -d'|' -f1 "$cacheFile" | sed 's/_/ /g' | dmenu -c -l $lineCount)" || exit 1
#   selectedName="$selection"
#   selection="$(echo $selection | sed 's/ /_/g')"
#
#   fullpath="$(awk -F'|' -v sel="$selection" '$1 == sel {print $2; exit}' "$cacheFile")"
#
#   [[ -n "$fullpath" ]] || exit 1
#   selectedFile="$fullpath"
# }

# Generate dmenu using $cacheFile (Set selectedFile)
_menuFromCache() {
  cacheFile="$HOME/.cache/dmenu_music_selector"
  [[ -f "$cacheFile" ]] || _updateMusicSelectorCache
  local selection fullpath

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
  }' "$cacheFile" | dmenu -c -l $lineCount
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

  [[ -n "$fullpath" ]] || exit 1
  selectedFile="$fullpath"
}

# Generate dmenu from $musicPath (Set selectedArtist)
_menuArtistSelection() {
  selectedArtist="$(/usr/bin/ls "$musicPath" | sed 's/_/ /g' | dmenu -c -l $lineCount)"
  selectedArtist="$(echo $selectedArtist | sed 's/ /_/g')"
}

# Generate dmu from $musicPath/$selectedArtist (Set selectedFile)
_menuArtistFileSelection() {
  [[ -z "$selectedArtist" ]] && exit 1
  selectedFile="$(/usr/bin/ls "$musicPath/$selectedArtist" | sed 's/_/ /g' | dmenu -c -l $lineCount)"
  selectedName="$selectedFile"
  selectedFile="$(echo $selectedFile | sed 's/ /_/g')"
}

# Main
if ! pgrep cmus; then
  kitty fish -c cmus && exit 0
fi

case "$mode" in
artist)
  _menuArtistSelection || exit 1
  _menuArtistFileSelection || exit 1
  cmus-remote -f "$musicPath/$selectedArtist/$selectedFile" && _notify center-text low "Now Playing: $selectedName"
  exit 0
  ;;

files)
  _menuFromCache || exit 1
  cmus-remote -f "$selectedFile" && _notify center-text low "Now Playing: $selectedName"
  exit 0
  ;;

update)
  _updateMusicSelectorCache && echo "[INFO] Music Selector Cache updated: $cacheFile"
  exit 0
  ;;

*)
  exit 1
  ;;
esac
