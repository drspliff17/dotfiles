#!/usr/bin/env bash

set -u

SOURCE_PATH="$HOME/Music/Songs"
DESTINATION="/sdcard/Music/Songs"

MODE="DRY"
VERBOSE=0
DEVICE=""
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
  local attempt=1

  while ((attempt <= 3)); do
    if _adb shell "mkdir -p $(_quote_remote "$path")" >/dev/null 2>&1; then
      return 0
    fi
    if _adb shell "test -d $(_quote_remote "$path")" >/dev/null 2>&1; then
      return 0
    fi
    ((attempt == 3)) || sleep 1
    ((attempt += 1))
  done

  _error "Could not create remote directory: $path"
}

_remote_mp3_list() {
  local path="$1"
  local recursive="${2:-0}"
  local command

  if [[ "$recursive" == 1 ]]; then
    command="find $(_quote_remote "$path") -type f -name '*.mp3' 2>/dev/null"
  else
    command="for file in $(_quote_remote "$path")/*.mp3; do [ -f \"\$file\" ] && printf '%s\\n' \"\$file\"; done; exit 0"
  fi
  _adb shell "$command"
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

_push_file() {
  local remote_dir="$1"
  local file="$2"
  local remote_file="$remote_dir/${file##*/}"
  local local_size remote_size attempt=1

  local_size="$(wc -c <"$file" | tr -d '[:space:]')" ||
    _error "Could not read local file size: $file"

  while ((attempt <= 3)); do
    if _adb push "$file" "$remote_dir/" >/dev/null; then
      _log "Pushed ${file##*/} -> $remote_dir"
      return 0
    fi

    remote_size="$(
      _adb shell "wc -c < $(_quote_remote "$remote_file")" 2>/dev/null |
        tr -d '[:space:]'
    )"
    if [[ "$remote_size" == "$local_size" ]]; then
      echo "[WARNING] ADB lost the copy response, but size verification passed: ${file##*/}" >&2
      return 0
    fi

    if ((attempt < 3)); then
      echo "[WARNING] Push failed; retrying ($attempt/3): ${file##*/}" >&2
      sleep 1
    fi
    ((attempt += 1))
  done

  _error "ADB push failed and destination size did not match: $file"
}

_wipe_destination() {
  local attempt=1 output

  while ((attempt <= 3)); do
    if output="$(_adb shell "rm -rf $(_quote_remote "$DESTINATION")" 2>&1)"; then
      return 0
    fi
    if _adb shell "test ! -e $(_quote_remote "$DESTINATION")" >/dev/null 2>&1; then
      echo "[WARNING] ADB reported a wipe error, but the destination is gone; continuing." >&2
      return 0
    fi

    if ((attempt < 3)); then
      echo "[WARNING] Wipe failed; retrying ($attempt/3). ${output}" >&2
      sleep 1
    fi
    ((attempt += 1))
  done

  [[ -n "$output" ]] && echo "[ADB] $output" >&2
  _error "Could not wipe destination: $DESTINATION"
}

_push_missing() {
  local directory="$1"
  local remote_dir="$2"
  local file fname
  local -a files=()
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

    _push_file "$remote_dir" "$file"
    ((pushed += 1))
  done

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

    if ! _adb shell "test -d $(_quote_remote "$remote_dir")" >/dev/null 2>&1; then
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
      for file in "${files[@]}"; do
        [[ -f "$file" ]] || continue
        _push_file "$remote_dir" "$file"
      done
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

    if ! _adb shell "test -d $(_quote_remote "$remote_dir")" >/dev/null 2>&1; then
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
      _adb shell "rm -f $(_quote_remote "$line")" >/dev/null ||
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
Files are checked as a group, then pushed one at a time for compatibility.
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
  _wipe_destination
  _adb_mkdir "$DESTINATION"
  _perform_transfer
  ;;
REVPARSE)
  _perform_revparse
  ;;
esac

echo "[FINISHED]"
