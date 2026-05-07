#!/usr/bin/env bash
set -u

SOURCE_PATH="$HOME/Music/Songs"
DESTINATION="/sdcard/Music/Songs"

MODE=""
VERBOSE=0

# Helpers

_log() {
  [[ "$VERBOSE" -eq 1 ]] && echo "$1"
}

adb_check() {
  adb get-state >/dev/null 2>&1 || {
    echo "[ERROR] No ADB device connected" >&2
    exit 1
  }
}

adb_mkdir() {
  adb shell "mkdir -p \"$1\"" >/dev/null 2>&1
}

_performTransfer() {
  local directory file dname fname
  local remote_dir remote_file
  local dmissing=0
  local fmissing=0
  local files

  case "$MODE" in

  "QUICK" | "DRY")

    shopt -s nullglob

    for directory in "$SOURCE_PATH"/*; do
      [[ ! -d "$directory" ]] && continue

      dname="$(basename "$directory")"
      remote_dir="$DESTINATION/$dname"

      if ! adb shell "[ -d \"$remote_dir\" ]" >/dev/null 2>&1; then
        if [[ "$MODE" == "DRY" ]]; then
          echo "Missing directory: $directory"
          ((dmissing++))
          continue
        else
          adb_mkdir "$remote_dir"
          _log "Created $remote_dir"
        fi
      fi

      files=("$directory"/*.mp3)
      ((${#files[@]} == 0)) && continue

      if [[ "$MODE" == "DRY" ]]; then
        remote_list="$(adb shell "find \"$remote_dir\" -type f 2>/dev/null | sed 's|.*/||'" || true)"

        for file in "${files[@]}"; do
          [[ -f "$file" ]] || continue
          fname="$(basename "$file")"

          if ! grep -Fxq "$fname" <<<"$remote_list"; then
            printf 'Missing file: %q\n' "$fname"
            ((fmissing++))
          fi
        done

        continue
      fi

      for file in "${files[@]}"; do
        [[ -f "$file" ]] || continue

        fname="$(basename "$file")"
        remote_file="$remote_dir/$fname"

        adb shell "[ -f \"$remote_file\" ]" >/dev/null 2>&1 && continue

        adb push "$file" "$remote_file" >/dev/null
        _log "Pushed $file -> $remote_file"
      done

    done

    [[ "$MODE" == "DRY" ]] && {
      echo "[Transfer Info] Missing Directories: $dmissing | Missing Files: $fmissing"
    }

    ;;

  "WIPE")
    _log "[Transfer Size: $(du -hs "$SOURCE_PATH" | cut -f1)]"

    adb shell "rm -rf \"$DESTINATION\""
    adb_mkdir "$DESTINATION"

    shopt -s nullglob
    for file in "$SOURCE_PATH"/*; do
      [[ -f "$file" ]] || continue
      adb push "$file" "$DESTINATION/" >/dev/null
      _log "Pushed $(basename "$file")"
    done
    ;;

  esac
}

# INIT
[[ ! -d "$SOURCE_PATH" ]] && {
  echo "[ERROR] Source path missing: $SOURCE_PATH" >&2
  exit 1
}

# ARGS
while [[ $# -gt 0 ]]; do
  case "$1" in
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
  *)
    shift
    ;;
  esac
done

[[ -z "$MODE" ]] && MODE="DRY"

# MAIN
adb_check

echo "[MODE = $MODE] Beginning ADB operation..."
_performTransfer
echo "[FINISHED]"
