#!/usr/bin/env bash

targDir="$1"
[[ -z "$targDir" ]] && targDir="$PWD"
[[ ! -d "$targDir" ]] && echo "[ERROR] Invaliid directory: $targDir" >&2 && exit 1

_getCleanedName() {
  local file="$(basename "$1")"
  local base clean
  if [[ "$file" == *"("* ]]; then
    base="${file%%(*}"
  else
    base="${file%%[*}"
  fi
  base="${base%.mp3}"
  clean="$(printf '%s' "$base" | tr -cd '[:alnum:] -')"
  clean="$(printf '%s' "$clean" | tr -s ' ')"
  clean="${clean#"${clean%%[![:space:]]*}"}"
  clean="${clean%"${clean##*[![:space:]]}"}"
  echo "$clean"
}

for file in "$targDir"/*.mp3; do
  newName="$(_getCleanedName "$file").mp3"
  newName="$(echo "$newName" | sed 's/ /_/g')"
  mv "$file" "$targDir/$newName"
done
