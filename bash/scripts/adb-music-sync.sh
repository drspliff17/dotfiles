#!/usr/bin/env bash

set -u

SOURCE_PATH="$HOME/Music/Songs"
DESTINATION="/sdcard/Music/Songs"

MODE=""
VERBOSE=0

SPECIFIED_DIRECTORIES=()
declare -A REMOTE_FILES=()
declare -A LOCAL_FILES=()

# Helpers

_log() {
  [[ "$VERBOSE" -eq 1 ]] && echo "$1"
  return 0
}

_error() {
  echo "[ERROR] $1" >&2
  exit 1
}

adb_check() {
  adb get-state >/dev/null 2>&1 || {
    echo "[ERROR] No ADB device connected" >&2
    exit 1
  }
}

_quote_remote() {
  local value="$1"
  value=${value//\'/\'\\\'\'}
  printf "'%s'" "$value"
}

adb_mkdir() {
  local remote_dir="$1"
  adb shell "mkdir -p $(_quote_remote "$remote_dir")" >/dev/null 2>&1
}

_get_remote_files() {
  local remote_dir="$1"
  local mp3_only="${2:-0}"
  local output path relative

  REMOTE_FILES=()
  if [[ "$mp3_only" == "1" ]]; then
    output="$(adb shell "find $(_quote_remote "$remote_dir") -type f -name '*.mp3' 2>/dev/null")" || return 1
  else
    output="$(adb shell "find $(_quote_remote "$remote_dir") -type f 2>/dev/null")" || return 1
  fi

  while IFS= read -r path; do
    path="${path%$'\r'}"
    [[ "$path" == "$remote_dir/"* ]] || continue
    relative="${path#"$remote_dir"/}"
    REMOTE_FILES["$relative"]=1
  done <<<"$output"
}

_resolve_directory() {
  local directory="$1"
  [[ "$directory" == /* ]] || directory="$SOURCE_PATH/$directory"
  while [[ "$directory" != "/" && "$directory" == */ ]]; do
    directory="${directory%/}"
  done
  printf '%s\n' "$directory"
}

_push_directory() {
  local directory="$1"
  local dname remote_dir
  local file fname remote_file

  [[ ! -d "$directory" ]] && {
    echo "[WARNING] Directory does not exist: $directory"
    return 0
  }

  dname="$(basename "$directory")"
  remote_dir="$DESTINATION/$dname"

  adb_mkdir "$remote_dir" || {
    echo "[ERROR] Could not create remote directory: $remote_dir" >&2
    return 1
  }

  _get_remote_files "$remote_dir" 1 || {
    echo "[ERROR] Could not list remote files: $remote_dir" >&2
    return 1
  }

  shopt -s nullglob
  for file in "$directory"/*.mp3; do
    [[ -f "$file" ]] || continue
    fname="$(basename "$file")"
    remote_file="$remote_dir/$fname"

    if [[ "${REMOTE_FILES["$fname"]+yes}" == yes ]]; then
      _log "Skipped $fname (already exists)"
      continue
    fi

    adb push "$file" "$remote_file" >/dev/null || {
      echo "[ERROR] ADB push failed for file: $file" >&2
      return 1
    }
    _log "Pushed $fname -> $remote_dir"
  done
}

_revparse_directory() {
  local directory="$1"
  local remote_dir="$2"
  local local_output path relative phone_file

  [[ ! -d "$directory" ]] && {
    echo "[WARNING] Directory does not exist: $directory"
    return 0
  }

  if ! adb shell "[ -d $(_quote_remote "$remote_dir") ]" >/dev/null 2>&1; then
    _log "Skipping missing remote dir: $remote_dir"
    ((missing_dirs++))
    return 0
  fi

  LOCAL_FILES=()
  local_output="$(find "$directory" -type f -print 2>/dev/null)" || return 1
  while IFS= read -r path; do
    [[ "$path" == "$directory/"* ]] || continue
    relative="${path#"$directory"/}"
    LOCAL_FILES["$relative"]=1
  done <<<"$local_output"

  _get_remote_files "$remote_dir" || {
    echo "[ERROR] Could not list remote files: $remote_dir" >&2
    return 1
  }

  for relative in "${!REMOTE_FILES[@]}"; do
    if [[ "${LOCAL_FILES["$relative"]+yes}" != yes ]]; then
      phone_file="$remote_dir/$relative"
      adb shell "rm -f $(_quote_remote "$phone_file")" >/dev/null 2>&1 || {
        echo "[ERROR] Could not delete remote file: $phone_file" >&2
        return 1
      }
      ((deleted++))
      _log "Deleted (revparse): $phone_file"
    fi
  done
}

_performTransfer() {
  local directory file dname fname
  local remote_dir remote_file
  local dmissing=0 fmissing=0
  local files
  local deleted=0 missing_dirs=0

  case "$MODE" in
  "QUICK" | "DRY")
    shopt -s nullglob
    for directory in "$SOURCE_PATH"/*; do
      [[ -d "$directory" ]] || continue

      dname="$(basename "$directory")"
      remote_dir="$DESTINATION/$dname"
      files=("$directory"/*.mp3)

      if [[ "$MODE" == "DRY" ]] && ! adb shell "[ -d $(_quote_remote "$remote_dir") ]" >/dev/null 2>&1; then
        echo "Missing directory: $directory"
        ((dmissing++))
        for file in "${files[@]}"; do
          [[ -f "$file" ]] || continue
          printf 'Missing file: %q\n' "$(basename "$file")"
          ((fmissing++))
        done
        continue
      fi

      ((${#files[@]} == 0)) && continue
      if [[ "$MODE" == "QUICK" ]]; then
        adb_mkdir "$remote_dir" || {
          echo "[ERROR] Could not create remote directory: $remote_dir" >&2
          return 1
        }
      fi

      _get_remote_files "$remote_dir" 1 || {
        echo "[ERROR] Could not list remote files: $remote_dir" >&2
        return 1
      }

      for file in "${files[@]}"; do
        [[ -f "$file" ]] || continue
        fname="$(basename "$file")"
        remote_file="$remote_dir/$fname"

        if [[ "${REMOTE_FILES["$fname"]+yes}" == yes ]]; then
          _log "Skipped $file: Already exists"
          continue
        fi
        if [[ "$MODE" == "DRY" ]]; then
          printf 'Missing file: %q\n' "$fname"
          ((fmissing++))
          continue
        fi

        adb push "$file" "$remote_file" >/dev/null || {
          echo "[ERROR] ADB push failed for file: $file" >&2
          return 1
        }
        _log "Pushed $file -> $remote_file"
      done
    done

    if [[ "$MODE" == "DRY" ]]; then
      echo "[Transfer Info] Missing Directories: $dmissing | Missing Files: $fmissing"
      [[ ! -t 1 && $(command -v notify-send 2>/dev/null) ]] && notify-send -u low -t 2000 -a center-text "[Transfer Info] Missing Directories: $dmissing | Missing Files: $fmissing"
    fi
    ;;

  "WIPE")
    _log "[Transfer Size: $(du -hs "$SOURCE_PATH" | cut -f1)]"
    echo "This will delete everything under $DESTINATION. Continue? [y/N]"
    read -r confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || {
      echo "[ABORTED]"
      return 0
    }

    adb shell "rm -rf $(_quote_remote "$DESTINATION")" >/dev/null || {
      echo "[ERROR] Could not wipe destination: $DESTINATION" >&2
      return 1
    }

    # DESTINATION stays absent so ADB creates that exact path for the source
    # directory, instead of nesting the source directory inside it
    adb push "$SOURCE_PATH" "$DESTINATION" || {
      echo "[ERROR] ADB directory push failed: $SOURCE_PATH -> $DESTINATION" >&2
      return 1
    }
    ;;

  "SPECIFIED")
    [[ ${#SPECIFIED_DIRECTORIES[@]} -gt 0 ]] || {
      echo "[ERROR] No directories specified" >&2
      return 1
    }
    for dname in "${SPECIFIED_DIRECTORIES[@]}"; do
      directory="$(_resolve_directory "$dname")"
      _push_directory "$directory" || return 1
    done
    ;;

  "REVPARSE")
    if ((${#SPECIFIED_DIRECTORIES[@]} == 0)); then
      _revparse_directory "$SOURCE_PATH" "$DESTINATION" || return 1
    else
      for dname in "${SPECIFIED_DIRECTORIES[@]}"; do
        directory="$(_resolve_directory "$dname")"
        remote_dir="$DESTINATION/$(basename "$directory")"
        _revparse_directory "$directory" "$remote_dir" || return 1
      done
    fi
    echo "[REVPARSE] Deleted files: $deleted | Missing dirs: $missing_dirs"
    ;;
  esac
}

# ARGS
while [[ $# -gt 0 ]]; do
  case "$1" in
  -f | --from)
    [[ $# -ge 2 && -d "$2" ]] || _error "Source path invalid: ${2:-}"
    SOURCE_PATH="$2"
    shift 2
    ;;
  -t | --to)
    [[ $# -ge 2 && -n "$2" ]] || _error "Destination path required"
    read -r -p "Are you sure you want to transfer to: $2? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || {
      echo "[ABORTED]"
      exit 1
    }
    DESTINATION="$2"
    shift 2
    ;;
  -v | --verbose)
    VERBOSE=1
    shift
    ;;
  -q | --quick)
    MODE="QUICK"
    shift
    ;;
  -w | --wipe)
    MODE="WIPE"
    shift
    ;;
  -s | --specific)
    MODE="SPECIFIED"
    shift
    while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
      SPECIFIED_DIRECTORIES+=("$1")
      shift
    done
    ;;
  -r | --revparse)
    MODE="REVPARSE"
    shift
    while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
      SPECIFIED_DIRECTORIES+=("$1")
      shift
    done
    ;;
  -c | --count)
    pc=$(mktemp)
    phone=$(mktemp)

    find "$HOME/Music/Songs" -type f -iname '*.mp3' -printf '%P\n' | sort >"$pc"
    adb shell "find '/sdcard/Music/Songs' -type f -iname '*.mp3' -print" |
      tr -d '\r' | sed 's#^/sdcard/Music/Songs/##' | sort >"$phone"

    echo "PC / Phone"
    wc -l "$pc" "$phone"
    comm -13 "$pc" "$phone"
    rm "$pc" "$phone"
    exit 0
    ;;
  -*)
    _error "Unknown Option: $1"
    ;;
  *)
    _error "Unexpected Value: $1"
    ;;
  esac
done

[[ -n "$MODE" ]] || MODE="DRY"
[[ -d "$SOURCE_PATH" ]] || _error "Source path missing: $SOURCE_PATH"

# MAIN
adb_check

echo "[MODE = $MODE] Beginning ADB operation..."
_performTransfer || exit 1
echo "[FINISHED]"
