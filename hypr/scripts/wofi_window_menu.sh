#/usr/bin/env bash

#TODO: Convert into the endless loop format
# Include some kind of tagging mode, and a private tag that gets filtered from selection views (except when modifying tagged windows)

#TODO: Swap from using address in window_menu directly, to grabbing PID of client, and recalling jq to find the address from that

#TODO: Cleanup functions / Mode switch, move per menu wofi setup into respective functions etc

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

ORIGIN_CACHE="$HOME/.config/wofi/state/wofi_window_menu_origin_client"
_cacheOriginClient() {
  cat <<EOF >"$ORIGIN_CACHE"
$(hyprctl activewindow -j | jq -r '.address')
EOF
}

MODES=("MOVE_CLIENT" "MOVE_WORKSPACE" "GOTO_CLIENT")

MODE=""
SELECTED_WINDOW=""
SELECTED_WORKSPACE=""
SELECTED_MONITOR=""

RETAIN_FOCUS=false
w_args=()

_cacheOriginClient

_cleanup() {
  _notify -a ct -t 5000 "STATS" "ACTIVE = $(hyprctl activewindow -j | jq '.address') | CACHED = $(cat $ORIGIN_CACHE)"
  if $RETAIN_FOCUS; then
    hyprctl dispatch "hl.dsp.focus({ window = 'address:$(cat "$ORIGIN_CACHE")' })"
  fi
  rm "$ORIGIN_CACHE"
}

trap '_cleanup' EXIT

# hyprctl workspaces -j | jq "map(select(.monitor == $monitor_name))"

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

_menuMonitor() {
  local selection
  _construct w_args
  selection="$(hyprctl monitors -j | jq -r '.[] | "\(.name)\t\(.id)"' | wofi -d "${w_args[@]}")"
  [[ -z "$selection" ]] && return 1
  SELECTED_MONITOR="$(echo "$selection" | cut -f2)"
}

_menuWorkspaces() {
  local selection
  local filter="${1:-false}"
  _construct w_args
  if [[ "$filter" = "false" ]]; then
    SELECTED_WORKSPACE="$(hyprctl workspaces -j | jq -r '.[] | .name' | wofi -d "${w_args[@]}")"
  else
    SELECTED_WORKSPACE="$(hyprctl workspaces -j | jq -r '.[] | select(.name | contains("special:") | not) | .name' | wofi -d "${w_args[@]}")"
  fi
  [[ -z "$SELECTED_WORKSPACE" ]] && return 1
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
    MODE="MOVE_CLIENT"
    shift
    ;;
  mvm | monitor)
    MODE="MOVE_WORKSPACE"
    shift
    ;;
  go | goto)
    MODE="GOTO_CLIENT"
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
  WOFI_HEIGHT="35%"
  WOFI_LINES="${#MODES[@]}"
  WOFI_CONFIG="$WOFI_C_CENTER"
  _menuMode || exit 1
}

case "$MODE" in
MOVE_CLIENT)
  [[ -z "$SELECTED_WINDOW" ]] && {
    WOFI_PROMPT="Select Client"
    WOFI_WIDTH="50%"
    WOFI_HEIGHT="35%"
    WOFI_LINES=""
    WOFI_CONFIG="$WOFI_C_CENTER"
    _menuWindow || exit 1
  }
  SELECTED_WORKSPACE="$(_inputPrompt "Input Target Workspace")"
  [[ -z "$SELECTED_WORKSPACE" ]] && exit 0
  _moveWindow "$SELECTED_WINDOW" "$SELECTED_WORKSPACE"
  ;;
MOVE_WORKSPACE)
  WOFI_PROMPT="Select Monitor"
  WOFI_WIDTH="50%"
  WOFI_HEIGHT="35%"
  WOFI_LINES="$(hyprctl monitors -j | jq 'length')"
  WOFI_CONFIG="$WOFI_C_CENTER"
  _menuMonitor || exit 1

  WOFI_PROMPT="Select Workspace to move ($SELECTED_MONITOR)"
  WOFI_LINES="$(hyprctl workspaces -j | jq 'length')"
  _menuWorkspaces || exit 1

  hyprctl dispatch "hl.dsp.workspace.move({ workspace = '$SELECTED_WORKSPACE', monitor = '$SELECTED_MONITOR' })" 2>&1 >/dev/null
  ;;
GOTO_CLIENT)
  [[ -z "$SELECTED_WINDOW" ]] && {
    WOFI_PROMPT="Select Client"
    WOFI_WIDTH="50%"
    WOFI_HEIGHT="35%"
    WOFI_LINES=""
    WOFI_CONFIG="$WOFI_C_CENTER"
    _menuWindow || exit 1
  }
  hyprctl dispatch "hl.dsp.focus({ window = 'address:$SELECTED_WINDOW' })" 2>&1 >/dev/null
  ;;
esac
