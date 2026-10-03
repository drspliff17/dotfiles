#!/usr/bin/env bash

set -u

SOURCE_PATH="$HOME/Music/Songs"
DESTINATION="/sdcard/Music/Songs"

MODE="DRY"
VERBOSE=0
DEVICE=""
BATCH_SIZE=64

declare -A REMOTE_NAMES=()

SELECTED_DIRECTORIES=()
SPECIFIED_DIRECTORIES=()

# Helpers

_log() {
  [[ "$VERBOSE" -eq 1 ]] && echo "$1"
}

_error() {
  echo "[ERROR] $1" >&2
  exit 1
}

# Quote one value for the Android device's POSIX shell.
_quote_remote() {
  local value="$1"
  value=${value//\'/\'\\\'\'}
  printf "'%s'" "$value"
}

_adb() {
  adb -s "$DEVICE" "$@"
}

_adb_check() {
  local devices=()
  local serial state output

  command -v adb >/dev/null 2>&1 || _error "adb was not found in PATH"

  if [[ -n "$DEVICE" ]]; then
    _adb get-state >/dev/null 2>&1 || _error "ADB device is not ready: $DEVICE"
    return
  fi

  output="$(adb devices)" || _error "Could not query ADB devices"
  while read -r serial state _; do
    [[ "$serial" == "List" || -z "$serial" ]] && continue
    [[ "$state" == "device" ]] && devices+=("$serial")
  done <<<"$output"

  case ${#devices[@]} in
  0) _error "No ADB device connected and ready" ;;
  1) DEVICE="${devices[0]}" ;;
  *)
    echo "[ERROR] More than one ADB device is connected; choose one with --device SERIAL:" >&2
    printf '  %s\n' "${devices[@]}" >&2
    exit 1
    ;;
  esac

  _adb get-state >/dev/null 2>&1 || _error "ADB device is not ready: $DEVICE"
}

_adb_mkdir() {
  local path="$1"
  _adb shell -T "mkdir -p $(_quote_remote "$path")" >/dev/null || _error "Could not create remote directory: $path"
}

_remote_mp3_list() {
  local path="$1"
  local recursive="${2:-0}"
  local command

  if [[ "$recursive" == 1 ]]; then
    command="find $(_quote_remote "$path") -type f -name '*.mp3' 2>/dev/null"
  else
    command="find $(_quote_remote "$path") -maxdepth 1 -type f -name '*.mp3' 2>/dev/null"
  fi
  _adb shell -T "$command"
}

_get_remote_names() {
  local remote_dir="$1"
  local output line name

  REMOTE_NAMES=()
  if ! output="$(_remote_mp3_list "$remote_dir")"; then
    return 1
  fi

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    name="${line##*/}"
    REMOTE_NAMES["$name"]=1
  done <<<"$output"
}

_push_batch() {
  local remote_dir="$1"
  shift

  (($# == 0)) && return
  _adb push "$@" "$remote_dir/" >/dev/null ||
    _error "ADB push failed for destination: $remote_dir"
  _log "Pushed batch of $# file(s) -> $remote_dir"
}

_push_missing() {
  local directory="$1"
  local remote_dir="$2"
  local file fname
  local -a files=() batch=()
  local pushed=0 skipped=0

  shopt -s nullglob
  files=("$directory"/*.mp3)

  _adb_mkdir "$remote_dir"
  _get_remote_names "$remote_dir" || _error "Could not list files in: $remote_dir"

  for file in "${files[@]}"; do
    [[ -f "$file" ]] || continue
    fname="${file##*/}"

    if [[ "${REMOTE_NAMES["$fname"]+yes}" == yes ]]; then
      ((skipped += 1))
      _log "Skipped $fname (already exists)"
      continue
    fi

    batch+=("$file")
    if ((${#batch[@]} >= BATCH_SIZE)); then
      _push_batch "$remote_dir" "${batch[@]}"
      ((pushed += ${#batch[@]}))
      batch=()
    fi
  done

  if ((${#batch[@]})); then
    _push_batch "$remote_dir" "${batch[@]}"
    ((pushed += ${#batch[@]}))
  fi

  _log "Directory complete: $pushed pushed, $skipped already present"
}

_list_source_directories() {
  local directory
  shopt -s nullglob
  for directory in "$SOURCE_PATH"/*; do
    [[ -d "$directory" ]] && printf '%s\0' "$directory"
  done
}

_selected_directories() {
  local directory name
  SELECTED_DIRECTORIES=()

  if [[ "$MODE" == SPECIFIED || "$MODE" == REVPARSE ]]; then
    ((${#SPECIFIED_DIRECTORIES[@]})) || _error "No directories specified"
    for name in "${SPECIFIED_DIRECTORIES[@]}"; do
      directory="$SOURCE_PATH/$name"
      if [[ ! -d "$directory" ]]; then
        echo "[WARNING] Directory does not exist: $directory" >&2
        continue
      fi
      SELECTED_DIRECTORIES+=("$directory")
    done
  else
    shopt -s nullglob
    for directory in "$SOURCE_PATH"/*; do
      [[ -d "$directory" ]] && SELECTED_DIRECTORIES+=("$directory")
    done
  fi
}

_perform_dry_run() {
  local directory dname remote_dir file fname
  local missing_dirs=0 missing_files=0 present_files=0
  local -a files=()

  _selected_directories
  for directory in "${SELECTED_DIRECTORIES[@]}"; do
    dname="${directory##*/}"
    remote_dir="$DESTINATION/$dname"

    shopt -s nullglob
    files=("$directory"/*.mp3)

    if ! _adb shell -T "test -d $(_quote_remote "$remote_dir")" >/dev/null 2>&1; then
      echo "Missing directory: $remote_dir"
      ((missing_dirs += 1))
      for file in "${files[@]}"; do
        [[ -f "$file" ]] || continue
        printf 'Missing file: %q\n' "${file##*/}"
        ((missing_files += 1))
      done
      continue
    fi

    _get_remote_names "$remote_dir" || _error "Could not list files in: $remote_dir"

    for file in "${files[@]}"; do
      [[ -f "$file" ]] || continue
      fname="${file##*/}"
      if [[ "${REMOTE_NAMES["$fname"]+yes}" == yes ]]; then
        ((present_files += 1))
      else
        printf 'Missing file: %q\n' "$fname"
        ((missing_files += 1))
      fi
    done
  done

  echo "[Transfer Info] Missing Directories: $missing_dirs | Missing Files: $missing_files | Present Files: $present_files"
}

_perform_transfer() {
  local directory dname remote_dir file

  _selected_directories
  for directory in "${SELECTED_DIRECTORIES[@]}"; do
    dname="${directory##*/}"
    remote_dir="$DESTINATION/$dname"

    if [[ "$MODE" == WIPE ]]; then
      shopt -s nullglob
      local -a files=("$directory"/*.mp3)
      _adb_mkdir "$remote_dir"
      local -a batch=()
      for file in "${files[@]}"; do
        [[ -f "$file" ]] || continue
        batch+=("$file")
        if ((${#batch[@]} >= BATCH_SIZE)); then
          _push_batch "$remote_dir" "${batch[@]}"
          batch=()
        fi
      done
      ((${#batch[@]})) && _push_batch "$remote_dir" "${batch[@]}"
    else
      _push_missing "$directory" "$remote_dir"
    fi
  done
}

_perform_revparse() {
  local directory dname remote_dir output line relpath file
  local deleted=0 missing_dirs=0
  local file_list
  local -A local_names=()

  _selected_directories
  for directory in "${SELECTED_DIRECTORIES[@]}"; do
    dname="${directory##*/}"
    remote_dir="$DESTINATION/$dname"

    if ! _adb shell -T "test -d $(_quote_remote "$remote_dir")" >/dev/null 2>&1; then
      _log "Skipping missing remote dir: $remote_dir"
      ((missing_dirs += 1))
      continue
    fi

    local_names=()
    file_list="$(mktemp "${TMPDIR:-$SOURCE_PATH}/.adb-music-sync.XXXXXX" 2>/dev/null)" ||
      file_list="$(mktemp "$SOURCE_PATH/.adb-music-sync.XXXXXX")" ||
      _error "Could not create a temporary file list"
    find "$directory" -type f -name '*.mp3' -print0 >"$file_list" || {
      rm -f "$file_list"
      _error "Could not scan local directory: $directory"
    }
    while IFS= read -r -d '' file; do
      relpath="${file#"$directory"/}"
      local_names["$relpath"]=1
    done <"$file_list"
    rm -f "$file_list"

    output="$(_remote_mp3_list "$remote_dir" 1)" || _error "Could not list files in: $remote_dir"
    while IFS= read -r line; do
      [[ "$line" == "$remote_dir/"* ]] || continue
      relpath="${line#"$remote_dir"/}"
      [[ "${local_names["$relpath"]+yes}" == yes ]] && continue

      _log "Deleting (revparse): $line"
      _adb shell -T "rm -f $(_quote_remote "$line")" >/dev/null ||
        _error "Could not delete remote file: $line"
      ((deleted += 1))
    done <<<"$output"
  done

  echo "[REVPARSE] Deleted files: $deleted | Missing dirs: $missing_dirs"
}

# ARGS
while (($#)); do
  case "$1" in
  -f | --from)
    (($# >= 2)) || _error "Source path required after $1"
    [[ -d "$2" ]] || _error "Source path invalid: $2"
    SOURCE_PATH="$2"
    shift 2
    ;;
  -t | --to)
    (($# >= 2)) || _error "Destination path required after $1"
    [[ -n "$2" ]] || _error "Destination path cannot be empty"
    read -r -p "Are you sure you want to transfer to: $2 [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || {
      echo "[ABORTED]"
      exit 1
    }
    DESTINATION="$2"
    shift 2
    ;;
  -d | --device)
    (($# >= 2)) || _error "Device serial required after $1"
    DEVICE="$2"
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
    [[ "$MODE" == REVPARSE ]] || MODE="SPECIFIED"
    shift
    while (($#)) && [[ ! "$1" =~ ^- ]]; do
      SPECIFIED_DIRECTORIES+=("$1")
      shift
    done
    ;;
  -r | --revparse)
    MODE="REVPARSE"
    shift
    ;;
  -h | --help)
    cat <<'HELP'
Usage: adb-music-sync.sh [OPTIONS]

  -f, --from PATH       Local source directory
  -t, --to PATH         Remote destination directory (prompts for confirmation)
  -d, --device SERIAL   ADB device serial (required when several are connected)
  -q, --quick           Push missing MP3 files; this is the default transfer mode
  -w, --wipe            Remove the destination, recreate it, then transfer
  -s, --specific DIR... Transfer only the named source directories
  -r, --revparse        Delete remote MP3 files absent from selected local dirs
  -v, --verbose         Show per-directory and skip details
  -h, --help            Show this help

With no transfer mode, report missing files without changing the device.
MP3 matching is by filename within each immediate source subdirectory.
Files are pushed in batches of 64 per directory.
HELP
    exit 0
    ;;
  -*) _error "Unknown option: $1" ;;
  *) _error "Unexpected value: $1" ;;
  esac
done

[[ -d "$SOURCE_PATH" ]] || _error "Source path missing: $SOURCE_PATH"
_adb_check

echo "[MODE = $MODE] Beginning ADB operation on $DEVICE..."

case "$MODE" in
DRY)
  _perform_dry_run
  ;;
QUICK | SPECIFIED)
  _perform_transfer
  ;;
WIPE)
  read -r -p "This will delete everything under $DESTINATION. Continue? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || {
    echo "[ABORTED]"
    exit 1
  }
  _adb shell -T "rm -rf $(_quote_remote "$DESTINATION")" || _error "Could not wipe destination: $DESTINATION"
  _adb_mkdir "$DESTINATION"
  _perform_transfer
  ;;
REVPARSE)
  _perform_revparse
  ;;
esac

echo "[FINISHED]"
