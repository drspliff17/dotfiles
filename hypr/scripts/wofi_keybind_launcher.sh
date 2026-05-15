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

UPDATE_BINDS="$HOME/.config/hypr/scripts/hypr_get_keybindings.sh"
JQ_ROOT='.[].Name | gsub("mainMod"; "MainMod")'
JQ_SUB='.[] | select(.Name == $sm) | .Items[] | "\(.Name | gsub("mainMod"; "MainMod")) :: \(.Command)"'

[[ ! -f "$UPDATE_BINDS" ]] && _notify -a ct -e -u normal "Could not find required script: $UPDATE_BINDS" && exit 1

WOFI_WIDTH="20%"
WOFI_HEIGHT="30%"
WOFI_CONFIG="$HOME/.config/wofi/center-align-config"

w_args=()
menu_stack=()

_update_args() {
  if [[ ${#menu_stack[@]} -eq 0 ]]; then
    WOFI_PROMPT="Select Submap"
    WOFI_WIDTH="20%"
  else
    local IFS=' › '
    WOFI_PROMPT="${menu_stack[*]}"
    WOFI_WIDTH="50%"
  fi
}

show_root() {
  while true; do

    _update_args
    _construct w_args

    choice="$(
      "$UPDATE_BINDS" | jq -r "$JQ_ROOT" | wofi -d "${w_args[@]}"
    )"

    [[ -z "$choice" ]] && exit 0

    menu_stack+=("$choice")
    show_submap "$choice"
    menu_stack=("${menu_stack[@]::${#menu_stack[@]}-1}")

  done
}

show_submap() {

  local sm="$1"

  while true; do

    _update_args
    _construct w_args

    choice="$(
      "$UPDATE_BINDS" | jq -r --arg sm "$sm" "$JQ_SUB" | wofi -d "${w_args[@]}"
    )"

    [[ -z "$choice" ]] && return

    cmd="${choice#* :: }"

    if [[ "$cmd" == submap:* ]]; then
      local next="${cmd#submap:}"
      menu_stack+=("$next")
      show_submap "$next"
      menu_stack=("${menu_stack[@]::${#menu_stack[@]}-1}")
      continue
    fi
    if [[ "$cmd" == hl.dsp.submap* ]]; then
      _notify -a ct -e "Current submap must be set via respective explicit keybind"
      return 1
    fi
    eval "$cmd"
    exit 0
  done
}

show_root
