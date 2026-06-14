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

EMOJI_FILE="$HOME/.local/share/snacks_merged.json"
MODE=""
w_args=()

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -c | copy)
    MODE="COPY"
    shift
    ;;
  -p | paste)
    MODE="PASTE"
    shift
    ;;
  *)
    _notify -a ct -e "Invalid Argument: $1" && exit 1
    ;;
  esac
done

[[ -z "$MODE" ]] && _notify -a ct -e "Expected Mode, provide either -c or -p flags to call" && exit 1

WOFI_PROMPT="Pick Emoji"
WOFI_WIDTH="25%"
WOFI_HEIGHT="40%"
WOFI_CONFIG="$WOFI_C_CENTER"
_construct w_args
SELECTED="$(printf '%s\n' "$(cat "$EMOJI_FILE" | jq -r '.[] | "\(.icon) | \(.name)"')" | wofi -d "${w_args[@]}" | cut -d'|' -f1 | tr -d ' ')"
[[ -z "$SELECTED" ]] && exit 0

case "$MODE" in
COPY)
  wl-copy "$SELECTED"
  _notify -a nhc "Copied: $SELECTED"
  ;;
PASTE)
  wl-copy "$SELECTED" && wl-paste
  _notify -a nhc "Pasted: $SELECTED"
  ;;
esac
