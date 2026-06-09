#!/usr/bin/env bash

#TODO: Set about renaming functions to prefix with _wofi, and their usages when i can be bothered

WOFI_LOG="$HOME/.config/wofi/state/wofi_lib.log"

WOFI_C_DEFAULT="$HOME/.config/wofi/config"
WOFI_C_CENTER="$HOME/.config/wofi/center-align-config"

WOFI_PROMPT=""
WOFI_WIDTH=""
WOFI_HEIGHT=""
WOFI_SORT=""
WOFI_CONFIG=""
WOFI_LINES=""
WOFI_COLUMNS=""

_wofiLog() {
  local msg="$1" level="${2:-INFO}" ts="$(date)"
  echo "[$ts] <$level> $msg" >>"$WOFI_LOG"
}

_captureMonitor() {
  local monitor="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"
  [[ -z "$monitor" ]] && return 1
  echo "$monitor" >~/.config/wofi/state/monitor_prelaunch
}

_construct() {
  local -n _out="$1"
  local prompt="${WOFI_PROMPT:-}"
  local width="${WOFI_WIDTH:-}"
  local height="${WOFI_HEIGHT:-}"
  local lines="${WOFI_LINES:-}"
  local columns="${WOFI_COLUMNS:-}"
  local config="${WOFI_CONFIG:-}"
  local sort="${WOFI_SORT:-}"

  _out=()
  [[ -n $WOFI_PROMPT ]] && _out+=("--prompt" "$WOFI_PROMPT")
  [[ -n $WOFI_WIDTH ]] && _out+=("--width" "$WOFI_WIDTH")
  [[ -n $WOFI_HEIGHT ]] && _out+=("--height" "$WOFI_HEIGHT")
  [[ -n $WOFI_COLUMNS ]] && _out+=("--columns" "$WOFI_COLUMNS")
  [[ -n $WOFI_LINES ]] && _out+=("--lines" "$WOFI_LINES")
  [[ -n $WOFI_SORT ]] && _out+=("-O" "$WOFI_SORT")
  [[ -n $WOFI_CONFIG ]] && _out+=("--conf" "$WOFI_CONFIG")

  _captureMonitor
}

# Like construct, except not explicitly tied to WOFI_** variables
_wofiConstructFromArgs() {
  [[ "$#" -lt 2 ]] && _wofiLog "$0::bash/lib/wofi_construct.sh::_constructFromArg: Not enough arguments provided" "ERROR" && return 1
  local -n _out="$1"
  shift
  local prompt width height columns lines sort config
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -p | --prompt)
      prompt="$2"
      shift 2
      ;;

    -w | --width)
      width="$2"
      shift 2
      ;;

    -h | --height)
      height="$2"
      shift 2
      ;;

    -c | --columns)
      columns="$2"
      shift 2
      ;;

    -l | --lines)
      lines="$2"
      shift 2
      ;;

    -s | --sort)
      sort="$2"
      shift 2
      ;;

    -cf | --config)
      config="$2"
      shift 2
      ;;

    -*)
      _wofiLog "$0::bash/lib/wofi_construct.sh::_constructFromArg: Invalid option given: $1" "ERROR"
      shift
      ;;
    *)
      _wofiLog "$0::bash/lib/wofi_construct.sh::_constructFromArg: Invalid value given: $1" "ERROR"
      shift
      ;;
    esac
  done

  _out=()
  [[ -n $prompt ]] && _out+=("--prompt" "$prompt")
  [[ -n $width ]] && _out+=("--width" "$width")
  [[ -n $height ]] && _out+=("--height" "$height")
  [[ -n $columns ]] && _out+=("--columns" "$columns")
  [[ -n $lines ]] && _out+=("--lines" "$lines")
  [[ -n $sort ]] && _out+=("-O" "$sort")
  [[ -n $config ]] && _out+=("--conf" "$config")

  _captureMonitor
  return 0
}

_wofiConfirmationPrompt() {
  local msg="Are You Sure?"
  local opts="Yes\nNo"

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -m | --msg | message)
      msg="$2"
      shift 2
      ;;
    -*)
      echo "[ERROR] _wofiConfirmationPrompt: Invalid Argument: $1" >&2 && return 1
      ;;
    *)
      echo "[ERROR] _wofiConfirmationPrompt: Invalid Option: $1" >&2 && return 1
      ;;
    esac
  done

  local selection w_args optCount
  optCount="${#opts[@]}"
  _wofiConstructFromArgs w_args -p "$msg" -w "10%" -l "$optCount" -E -cf "$WOFI_C_CENTER"
  selection="$(echo -e "$opts" | wofi -d "${w_args[@]}")"
  case "$selection" in
  Yes)
    return 0
    ;;
  *)
    return 1
    ;;
  esac
}
