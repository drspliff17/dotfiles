#!/usr/bin/env bash

# Wrapper for eyeD3, for correcting .mp3 meta data
fixMP3_Meta() {
  if [[ -z "$1" ]]; then
    cat <<'HELP'
MP3 Meta Data Correction
------------------------
Arguments
-a  | --artist   [value]  : Set Artist Name Data **required
-sa | --album    [value]  : Set Album Data
------------------------
Modes (* refer to Info)
-f  | --files    [values] : Specify which files are processed, must be final argument of command call when used

-da | --dump-all          : Outputs meta data for all .mp3 in CWD
-tr | --trim              : Removes metadata from all .mp3 files in CWD                               (*)
-g  | --get [file]  [opt] : Retrieve the Metadata of a specified file, optionally specify the tag
-gma| --get-missing-album : Retrieve a line separated list of .mp3 filenames, with empty album tags   (*)
-fna| --files-no-album    : Apply to any .mp3 with empty album tags

------------------------
Flags
-q  | --quiet             : Pass --quiet flag to eyeD3 calls
-t  | --title             : Set Title Data (File name, but sed/_/[space])
------------------------
Info

  Available modes = [default, alt, trim, get, get_missing]: modes are MUTUALLY EXCLUSIVE

  - Default behaviour, loop all .mp3 in cwd, call eyeD3 with passed arguments
    - if -t/--title is passed, use filename of .mp3 (replacing _ with space)

  - Alt behaviour, loop given filenames in cwd, call eyeD3 with passed arguments
    - example: fixMP3_Meta -a "Beartooth" -f file1.mp3 file4.mp3 file6.mp3

  - Trim behaviour, loop all .mp3 in cwd, remove all metadata except [title] [album] [artist]

  - Get behaviour, returns all Metadata for give .mp3, or optionally, retrieves specificied
    tags. Currently, valid tags are: [artist] [title] [album]


  [Info] Messages are >&2
-------------------------
Examples
  fixMP3_Meta -a "artistName" -t
  fixMP3_Meta -sa "albumName" -f example1.mp3 example13.mp3 example42.mp3
  fixMP3_Meta -g "Filename.mp3"
  fixMP3_Meta -g "Filename.mp3" album
  fixMP3_Meta -tr -q
HELP
    return 1
  fi

  # Helpers
  _changeFileDataD3() {
    local -n base_args=$1
    local file=$2

    local args=("${base_args[@]}")

    if [[ "$useFilenameAsTitle" -eq 0 ]]; then
      title="${file//_/ }"
      title="${title%.mp3}"
      args+=(--title "$title")
    fi

    args+=("$file")
    eyeD3 "${args[@]}"
    return 0
  }

  _retrieveFileDataD3() {
    local file="$1"
    local tag="$2"
    [[ -z "$1" ]] && return 1
    if [[ -z "$tag" ]]; then
      eyeD3 "$file"
      return 0
    fi

    case "$tag" in
    title | artist | album)
      eyeD3 --no-color "$file" | grep "^$tag:" | cut -d: -f2- | sed 's/^[[:space:]]*//'
      return 0
      ;;

    *)
      echo "[ERROR]: _retrieveFileDataD3: Invalid Tag Option [valid = title, album, artist]" >&2 && return 1
      ;;
    esac
  }

  # Def
  local mode=""

  local artistName=""
  local albumName=""
  local getTag=""

  local useFilenameAsTitle=1
  local quietMode=1

  local specifiedFiles=()
  local eyeArguments=()

  # Parse Args
  while [[ "$#" -gt 0 ]]; do
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
      shift
      useFilenameAsTitle=0
      ;;
    -f | --files)
      shift
      if [[ -z "$mode" ]]; then
        mode="alt"
      else
        echo "[ERROR] Mode cannot be mutated, after being set. Current Mode: $mode" >&2 && return 1
      fi
      specifiedFiles=("$@")
      break
      ;;
    -g | --get)
      shift
      if [[ -z "$mode" ]]; then
        mode="get"
      else
        echo "[ERROR] Mode cannot be mutated, after being set. Current Mode: $mode" >&2 && return 1
      fi
      specifiedFiles+=("$1")
      shift
      getTag="$1"
      shift
      ;;
    -gma | --get-missing-album)
      shift
      if [[ -z "$mode" ]]; then
        mode="get_missing"
      else
        echo "[ERROR] Mode cannot be mutated, after being set. Current Mode: $mode" >&2 && return 1
      fi
      ;;
    -fna | --files-no-album)
      shift
      if [[ -z "$mode" ]]; then
        mode="files_no_album"
      else
        echo "[ERROR] Mode cannot be mutated, after being set. Current Mode: $mode" >&2 && return 1
      fi
      ;;
    -tr | --trim)
      shift
      if [[ -z "$mode" ]]; then
        mode="trim"
      else
        echo "[ERROR] Mode cannot be mutated, after being set. Current Mode: $mode" >&2 && return 1
      fi
      ;;
    -q | --quiet)
      shift
      eyeArguments+=(--quiet)
      quietMode=0
      ;;
    -da | --dump-all)
      shift
      if [[ -z "$mode" ]]; then
        mode="dump_all"
      else
        echo "[ERROR] Mode cannot be mutated, after being set. Current Mode: $mode" >&2 && return 1
      fi
      ;;
    -* | --*)
      echo "[ERROR] Unknown Option: $1" >&2 && return 1
      ;;
    *)
      echo "[ERROR] Unknown Value: $1" >&2 && return 1
      ;;
    esac
  done

  # Execution
  [[ -z "$mode" ]] && mode="default"
  case "$mode" in
  default)
    if [[ -n "$albumName" ]]; then
      read -rp "[WARNING] This will set all .mp3 files in $PWD to album: $albumName. Confirm [Y/y]: " confirm
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted fixMP3_Meta" && return 1
      fi
    fi
    for f in *.mp3; do
      _changeFileDataD3 eyeArguments "$f"
    done
    return 0
    ;;

  alt)
    for f in "${specifiedFiles[@]}"; do
      if [[ -f "$f" ]]; then
        _changeFileDataD3 eyeArguments "$f"
      else
        echo "[ERROR] _changeFileDataD3: file not found: $f" >&2
      fi
    done
    return 0
    ;;

  get)
    if [[ ! -f "$specifiedFiles" ]]; then
      echo "[ERROR] Specified File cannot be found: $specifiedFiles" >&2 && return 1
    fi
    _retrieveFileDataD3 "$specifiedFiles" "$getTag"
    return 0
    ;;

  get_missing)
    echo "[INFO] Finding files without album, this may take a moment..." >&2
    for f in *.mp3; do
      if [[ -z "$(fixMP3_Meta -g "$f" album)" ]]; then
        echo "$f"
      fi
    done
    return 0
    ;;

  files_no_album)
    read -rp "[WARNING] This will apply to any file with an empty album tag. Confirm [Y/y]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "Aborted fixMP3_Meta" && return 1
    fi
    echo "[INFO] Finding files without album, this may take a moment..." >&2
    fixMP3_Meta -gma 2>/dev/null | while IFS= read -r f; do
      _changeFileDataD3 eyeArguments "$f"
    done
    return 0
    ;;

  trim)
    read -rp "[WARNING] This will remove metadata from all .mp3 in $PWD. Only the Title, Artist, and Album tags will be preserved. Confirm [Y/y]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "Aborted fixMP3_Meta" && return 1
    fi
    for f in *.mp3; do
      local _data="$(fixMP3_Meta -g "$f" 2>/dev/null)"
      local _artist="$(awk -F': ' '/^artist:/ {print $2}' <<<"$_data")"
      local _album="$(awk -F': ' '/^album:/ {print $2}' <<<"$_data")"
      local _title="$(awk -F': ' '/^title:/ {print $2}' <<<"$_data")"

      if [[ "$quietMode" -eq 0 ]]; then
        eyeD3 --remove-all "$f" >/dev/null
        eyeD3 -a "$_artist" -A "$_album" -t "$_title" "$f" >/dev/null
      else
        eyeD3 --remove-all "$f"
        eyeD3 -a "$_artist" -A "$_album" -t "$_title" "$f"
      fi
      echo "Removed Metadata: $f"
    done
    return 0
    ;;
  dump_all)
    echo "[INFO] Dumping all .mp3 metadata in $CWD, this may take a moment..." >&2
    for f in *.mp3; do
      fixMP3_Meta -g "$f"
    done
    return 0
    ;;
  esac

}
