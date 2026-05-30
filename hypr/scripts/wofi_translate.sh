#!/usr/bin/env bash

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

STARTED_SERVER=false
SERVER_PID=""

if ! nc -z -w 2 127.0.0.1 5000; then
  cd "$HOME/dev/LibreTranslate" || {
    _notify -a ct -e "Could not find server directory" && exit 1
  }

  setsid hatch run dev &
  SERVER_PID=$!
  STARTED_SERVER=true

  for i in {1..20}; do
    if nc -z -w 2 127.0.0.1 5000; then
      break
    fi
    sleep 0.5
  done
fi

_cleanup() {
  [[ "$STARTED_SERVER" = true ]] && {
    _notify -a ct "Stopping server $SERVER_PID"
    kill "$SERVER_PID"
  }
}

trap '_cleanup' EXIT

LANGS=()
MSG=""
SRC_LANG=""
TRG_LANG=""
LANG_COUNT=0
w_args=()

_gatherLanguages() {
  local ld="$HOME/dev/LibreTranslate/libretranslate/locales"
  local dirs
  shopt -s nullglob
  dirs=("$ld"/*)
  shopt -u nullglob
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] && LANGS+=("$(basename "$d")")
  done
  LANGS+=("en")
  LANG_COUNT="${#dirs[@]}"
  [[ "$LANG_COUNT" -eq 0 ]] && _notify -a ct -e "No languages found inside $ld" && exit 1
  return 0
}

_selectSourceLanguage() {
  WOFI_PROMPT="Pick Source Language"
  WOFI_WIDTH="15%"
  if [[ "$LANG_COUNT" -lt 10 ]]; then
    WOFI_LINES="$LANG_COUNT"
  else
    WOFI_HEIGHT="35%"
  fi

  _construct w_args
  SRC_LANG="$(printf '%s\n' "${LANGS[@]}" | wofi -d "${w_args[@]}")"
  [[ -z "$SRC_LANG" ]] && _notify -a ct "Source language required" && exit 1
  _isValidLanguage "$SRC_LANG" || exit 1
}

_selectTargetLanguage() {
  WOFI_PROMPT="Pick Target Language"
  WOFI_WIDTH="15%"
  if [[ "$LANG_COUNT" -lt 10 ]]; then
    WOFI_LINES="$LANG_COUNT"
  else
    WOFI_HEIGHT="35%"
  fi

  _construct w_args
  TRG_LANG="$(printf '%s\n' "${LANGS[@]}" | wofi -d "${w_args[@]}")"
  [[ -z "$TRG_LANG" ]] && _notify -a ct "Target language required" && exit 1
  _isValidLanguage "$TRG_LANG" || exit 1
}

_selectMessage() {
  WOFI_PROMPT="Enter Text To Translate"
  WOFI_WIDTH="50%"
  WOFI_LINES=0
  WOFI_HEIGHT="10%"

  _construct w_args
  MSG="$(wofi -d "${w_args[@]}")"
  [[ -z "$MSG" ]] && _notify -a ct -e "Message required!" && exit 1
}

_isValidLanguage() {
  local t="$1"
  local lang
  for lang in "${LANGS[@]}"; do
    [[ "$lang" == "$t" ]] && return 0
  done
  _notify -a ct -e "Invalid Language: $t"
  return 1
}

_gatherLanguages

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -m | msg)
    shift
    MSG="$1"
    shift
    ;;
  -s | src)
    shift
    SRC_LANG="$1"
    _isValidLanguage "$SRC_LANG" || exit 1
    shift
    ;;
  -t | trg)
    shift
    TRG_LANG="$1"
    _isValidLanguage "$TRG_LANG" || exit 1
    shift
    ;;
  -p | paste)
    shift
    CV="$(clipvault get --index 1)"
    [[ -z "$CV" ]] && _notify -a ct -e "Nothing inside Clipvault!" && exit 1
    MSG="$CV"
    ;;
  -*)
    _notify -a ct -e "Invalid option: $1" && exit 1
    ;;
  *)
    _notify -a ct -e "Invalid value: $1" && exit 1
    ;;
  esac
done

[[ -z "$SRC_LANG" ]] && _selectSourceLanguage
[[ -z "$TRG_LANG" ]] && _selectTargetLanguage
[[ -z "$MSG" ]] && _selectMessage

Result="$("$HOME/.config/bash/scripts/translate.sh" "$MSG" "$SRC_LANG" "$TRG_LANG")"
[[ -z "$Result" ]] && _notify -a ct -e "Response Empty!" && exit 1
echo "$Result" | wl-copy
_notify -a ct -t 3000 "$Result" && exit 0
