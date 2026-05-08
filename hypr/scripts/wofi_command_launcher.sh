#!/usr/bin/env bash

#TODO: Add comments & cleanup

wofi_command_line_data="$HOME/dev/data/wofi_command_line.yml"
[[ ! -f "$wofi_command_line_data" ]] && notify-send -u normal -t 2000 -a center-text "Missing Expected File: $wofi_command_line_data" && exit 1

w_prompt=""
w_width="10%"
w_height="50%"
w_conf="$HOME/.config/wofi/center-align-config"
w_columns=""
w_lines=""
w_args=()

menu_stack=()

_update_prompt() {
  if [[ ${#menu_stack[@]} -eq 0 ]]; then
    w_prompt="Select Command"
  else
    w_prompt="$(
      IFS=' › '
      echo "${menu_stack[*]}"
    )"
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

show_menu() {
  local path="$1"
  local is_root="$2"

  while true; do
    local count choice selection item_path
    declare -A item_map=()

    count="$(yq "$path | length" "$wofi_command_line_data")"
    [[ "$count" -eq 0 ]] && return 1

    _update_prompt
    _constructArgs

    while IFS=$'\t' read -r name index; do
      item_map["$name"]="$index"
    done < <(
      yq -r "$path | to_entries[] | [.value.Name, .key] | @tsv" \
        "$wofi_command_line_data"
    )

    local options=("${!item_map[@]}")
    options+=("✕ Exit")

    w_lines="${#options[@]}"
    _constructArgs
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
