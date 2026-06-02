#!/usr/bin/env bash

#TODO: Add comments & cleanup

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

killall wofi
wofi_command_line_data="${1:-$HOME/dev/data/wofi_command_line.yml}"
[[ ! -f "$wofi_command_line_data" ]] && _notify -u normal -t 2000 -a ct "Missing Expected File: $wofi_command_line_data" && exit 1

WOFI_WIDTH="10%"
WOFI_HEIGHT="50%"
WOFI_CONFIG="$HOME/.config/wofi/center-align-config"

w_args=()
menu_stack=()

_update_prompt() {
  if [[ ${#menu_stack[@]} -eq 0 ]]; then
    WOFI_PROMPT="Select Command"
  else
    WOFI_PROMPT="$(
      local IFS=' › '
      echo "${menu_stack[*]}"
    )"
  fi
}

show_menu() {
  local path="$1"
  local is_root="$2"

  while true; do
    local count choice selection item_path
    declare -A item_map=()

    count="$(yq "$path | length" "$wofi_command_line_data")"
    [[ "$count" -eq 0 ]] && return 1

    _update_prompt
    _construct w_args

    while IFS=$'\t' read -r name index; do
      item_map["$name"]="$index"
    done < <(
      yq -r "$path | to_entries[] | [.value.Name, .key] | @tsv" \
        "$wofi_command_line_data"
    )

    local options=("${!item_map[@]}")
    options+=("✕ Exit")

    WOFI_LINES="${#options[@]}"
    _construct w_args
    choice="$(printf "%s\n" "${options[@]}" | wofi -d "${w_args[@]}")"
    [[ -z "$choice" ]] && return 1
    [[ "$choice" = "✕ Exit" ]] && pkill -f $HOME/.config/hypr/scripts/wofi_command_launcher.sh

    selection="${item_map[$choice]}"
    item_path="$path[$selection]"

    # Execute command
    if yq -e "$item_path | has(\"Command\")" "$wofi_command_line_data" >/dev/null; then
      eval "$(yq -r "$item_path.Command" "$wofi_command_line_data")"
      if yq -e "$item_path.Exit == true" "$wofi_command_line_data" >/dev/null; then
        exit 0
      fi
      return 0
    fi

    # Enter submenu
    if yq -e "$item_path | has(\"Items\")" "$wofi_command_line_data" >/dev/null; then
      menu_stack+=("$choice")
      show_menu "$item_path.Items" false
      menu_stack=("${menu_stack[@]::${#menu_stack[@]}-1}")
    fi
  done
}

# Main Loop
show_menu '.Commands' true
exit 0
