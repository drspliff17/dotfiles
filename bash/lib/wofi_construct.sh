#!/usr/bin/env bash

WOFI_C_DEFAULT="$HOME/.config/wofi/config"
WOFI_C_CENTER="$HOME/.config/wofi/center-align-config"

WOFI_PROMPT=""
WOFI_WIDTH=""
WOFI_HEIGHT=""
WOFI_SORT=""
WOFI_CONFIG=""
WOFI_LINES=""
WOFI_COLUMNS=""

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
}
