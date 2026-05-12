#!/usr/bin/env bash

UPDATE_BINDS="$HOME/.config/hypr/scripts/hypr_get_keybindings.sh"
JQ_ROOT='.[].Name | gsub("mainMod"; "MainMod")'
JQ_SUB='.[] | select(.Name == $sm) | .Items[] | "\(.Name | gsub("mainMod"; "MainMod")) :: \(.Command)"'

[[ ! -f "$UPDATE_BINDS" ]] && notify_send -a center-text -t 1500 -u low "ERROR" "Could not find required script: $UPDATE_BINDS" && exit 1

w_prompt=""
w_width="40%"
w_height="30%"
w_conf="$HOME/.config/wofi/center-align-config"
w_columns=""
w_lines=""
w_args=()

menu_stack=()

_update_prompt() {
  if [[ ${#menu_stack[@]} -eq 0 ]]; then
    w_prompt="Select Submap"
  else
    IFS=' › '
    w_prompt="${menu_stack[*]}"
    unset IFS
  fi
}

_constructArgs() {
  w_args=()

  w_args+=("--prompt" "$w_prompt")
  w_args+=("--width" "$w_width")
  w_args+=("--height" "$w_height")

  [[ -n $w_columns ]] && w_args+=("--columns" "$w_columns")
  [[ -n $w_lines ]] && w_args+=("--lines" "$w_lines")
  [[ -n $w_conf ]] && w_args+=("--conf" "$w_conf")
}

show_root() {
  while true; do

    _update_prompt
    _constructArgs

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

    _update_prompt
    _constructArgs

    choice="$(
      "$UPDATE_BINDS" | jq -r --arg sm "$sm" "$JQ_SUB" | wofi -d "${w_args[@]}"
    )"

    [[ -z "$choice" ]] && return

    cmd="${choice#* :: }"

    if [[ "$cmd" == submap:* ]]; then
      next="${cmd#submap:}"
      menu_stack+=("$next")
      show_submap "$next"
      menu_stack=("${menu_stack[@]::${#menu_stack[@]}-1}")
      continue
    fi
    if [[ "$cmd" == hl.dsp.submap* ]]; then
      notify-send -a center-text -t 1500 -u low "Warning" "Current submap must be set via respective explicit keybind"
      return 1
    fi
    eval "$cmd"
    exit 0
  done
}

show_root
