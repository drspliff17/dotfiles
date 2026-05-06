#!/usr/bin/env bash

# Wrapper for eyeD3 for correcting .mp3 metadata

#####################################
# HELP
#####################################
if [[ $# -eq 0 ]]; then
  cat <<'HELP'
MP3 Meta Data Correction
------------------------
Arguments
-a  | --artist   [value]  : Set Artist Name (required for write modes)
-sa | --album    [value]  : Set Album Data
-t  | --title             : Use filename as title

-f  | --files    [values] : Specify files (must be last when used)

-da | --dump-all          : Dump metadata for all .mp3
-tr | --trim              : Remove metadata except title/artist/album
-g  | --get [file] [tag]  : Get metadata
-gma| --get-missing-album : List files missing album
-fna| --files-no-album    : Apply to files with empty album tag

-q  | --quiet             : Quiet eyeD3 output

Modes are mutually exclusive.
HELP
  exit 1
fi

#####################################
# HELPERS
#####################################
_changeFileDataD3() {
  local file="$1"

  local args=("${eyeArguments[@]}")

  if [[ "$useFilenameAsTitle" -eq 0 ]]; then
    title="${file//_/ }"
    title="${title%.mp3}"
    args+=(--title "$title")
  fi

  args+=("$file")
  eyeD3 "${args[@]}"
}

_retrieveFileDataD3() {
  local file="$1"
  local tag="${2:-}"

  if [[ -z "$tag" ]]; then
    eyeD3 "$file"
    return
  fi

  case "$tag" in
  title | artist | album)
    eyeD3 --no-color "$file" | grep "^$tag:" | cut -d: -f2- | sed 's/^[[:space:]]*//'
    ;;
  *)
    echo "[ERROR] Invalid tag (title|artist|album)" >&2
    exit 1
    ;;
  esac
}

#####################################
# DEFAULTS
#####################################
mode=""
artistName=""
albumName=""
getTag=""
useFilenameAsTitle=1
quietMode=1

specifiedFiles=()
eyeArguments=()

#####################################
# PARSE ARGS
#####################################
while [[ $# -gt 0 ]]; do
  case "$1" in
  -a | --artist)
    shift
    artistName="$1"
    eyeArguments+=(--artist "$artistName")
    shift
    ;;

  -sa | --album)
    shift
    albumName="$1"
    eyeArguments+=(--album "$albumName")
    shift
    ;;

  -t | --title)
    useFilenameAsTitle=0
    shift
    ;;

  -f | --files)
    shift
    mode="alt"
    specifiedFiles=("$@")
    break
    ;;

  -g | --get)
    shift
    mode="get"
    specifiedFiles=("$1")
    shift
    getTag="${1:-}"
    shift || true
    ;;

  -gma | --get-missing-album)
    mode="get_missing"
    shift
    ;;

  -fna | --files-no-album)
    mode="files_no_album"
    shift
    ;;

  -tr | --trim)
    mode="trim"
    shift
    ;;

  -da | --dump-all)
    mode="dump_all"
    shift
    ;;

  -q | --quiet)
    quietMode=0
    eyeArguments+=(--quiet)
    shift
    ;;

  *)
    echo "[ERROR] Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

[[ -z "$mode" ]] && mode="default"

#####################################
# EXECUTION
#####################################
case "$mode" in

default)
  for f in *.mp3; do
    [[ -f "$f" ]] && _changeFileDataD3 "$f"
  done
  ;;

alt)
  for f in "${specifiedFiles[@]}"; do
    [[ -f "$f" ]] && _changeFileDataD3 "$f"
  done
  ;;

get)
  _retrieveFileDataD3 "${specifiedFiles[0]}" "$getTag"
  ;;

get_missing)
  for f in *.mp3; do
    data="$(eyeD3 "$f" 2>/dev/null || true)"
    echo "$data" | grep -q "^album:" || echo "$f"
  done
  ;;

files_no_album)
  for f in *.mp3; do
    data="$(eyeD3 "$f" 2>/dev/null || true)"
    echo "$data" | grep -q "^album:" || continue
    _changeFileDataD3 "$f"
  done
  ;;

trim)
  for f in *.mp3; do
    eyeD3 --remove-all "$f" >/dev/null
    echo "[TRIMMED] $f"
  done
  ;;

dump_all)
  for f in *.mp3; do
    echo "=== $f ==="
    eyeD3 "$f"
  done
  ;;

esac
