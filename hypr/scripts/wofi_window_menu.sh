#/usr/bin/env bash

#TODO: Convert into the endless loop format
# Include some kind of tagging mode, and a private tag that gets filtered from selection views (except when modifying tagged windows)

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

MODES=("MOVE_WORKSPACE" "GOTO")

MODE=""
SELECTED_WINDOW=""
SELECTED_WORKSPACE=""
RETAIN_FOCUS=false
ORIGIN_WINDOW="$(hyprctl activewindow -j | jq '.address')"
w_args=()

_returnFocus() {
  if $RETAIN_FOCUS; then
    hyprctl dispatch "hl.dsp.focus({ window = '$ORIGIN_WINDOW' })"
  fi
}

trap '_returnFocus' EXIT

_validWorkspace() {
  local target="$1"
  [[ "$target" == "special:"* || "$target" =~ ^[0-9]+$ ]] && {
    [[ "$target" -gt 10 ]] && return 1
    return 0
  }
  return 1
}

_moveWindow() {
  local win="$1"
  local dest="$2"
  if ! _validWorkspace "$dest"; then
    _notify -a ct -e "Invalid workspace given: $dest" && return 1
  fi
  hyprctl dispatch "hl.dsp.window.move({ window = 'address:$win', workspace = '$dest' })" 2>&1 >/dev/null && return 0
  _notify -a ct -e "Failed to dispatch dsp.window.move. Window ($win) : Target ($dest)" && return 1
}

_menuWindow() {
  [[ "$(hyprctl clients -j | jq 'length')" -eq 0 ]] && _notify -a ct "No Clients Found!" && return 1
  local selection
  _construct w_args
  selection="$(hyprctl clients -j | jq -r '.[] | "\(.address)\t[WS:\(.workspace.name)]\t \(.class) \t|\t \(.title) | PID:\(.pid)"' |
    wofi -d "${w_args[@]}")"
  [[ -z "$selection" ]] && return 1
  SELECTED_WINDOW="$(echo "$selection" | cut -f1)"
}

_menuMode() {
  local selection
  _construct w_args
  selection="$(printf '%s\n' "${MODES[@]}" | wofi -d "${w_args[@]}")"
  [[ -z "$selection" ]] && return 1
  MODE="$selection"
}

_inputPrompt() {
  local input
  WOFI_PROMPT="$1"
  WOFI_WIDTH="65%"
  WOFI_HEIGHT="5%"
  WOFI_LINES=1
  _construct w_args
  input="$(echo -e '\n' | wofi -d "${w_args[@]}")"
  [[ -z "$input" ]] && return 1
  echo "$input"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  mv | move)
    MODE="MOVE"
    shift
    ;;
  go | goto)
    MODE="GOTO"
    shift
    ;;
  -r | retain)
    RETAIN_FOCUS=true
    shift
    ;;
  esac
done

[[ -z "$MODE" ]] && {
  WOFI_PROMPT="Select Mode"
  WOFI_WIDTH="15%"
  WOFI_CONFIG="$WOFI_C_CONFIG"
  if [[ "${#MODES[@]}" -lt 10 ]]; then
    WOFI_LINES="${#MODES[@]}"
    WOFI_HEIGHT=""
  else
    WOFI_LINES=""
    WOFI_HEIGHT="35%"
  fi
  _menuMode || exit 1
}

[[ -z "$SELECTED_WINDOW" ]] && {
  WOFI_PROMPT="Select Client"
  WOFI_WIDTH="50%"
  WOFI_CONFIG="$WOFI_C_CONFIG"
  if [[ "$(hyprctl clients -j | jq 'length')" -lt 5 ]]; then
    WOFI_LINES="${#MODES[@]}"
    WOFI_HEIGHT=""
  else
    WOFI_LINES=""
    WOFI_HEIGHT="35%"
  fi
  _menuWindow || exit 1
}

case "$MODE" in
MOVE_WORKSPACE)
  SELECTED_WORKSPACE="$(_inputPrompt "Input Target Workspace")"
  [[ -z "$SELECTED_WORKSPACE" ]] && exit 0
  _moveWindow "$SELECTED_WINDOW" "$SELECTED_WORKSPACE"
  ;;
GOTO)
  hyprctl dispatch "hl.dsp.focus({ window = 'address:$SELECTED_WINDOW' })" 2>&1 >/dev/null
  ;;
esac
