#!/usr/bin/env bash

declare -A cmd_map
wofi_command_line_data="$HOME/stuff/wofi_command_line.yml"
[[ ! -f "$wofi_command_line_data" ]] && notify-send -u normal -t 2000 -a center-text "Missing Expected File: $wofi_command_line_data" && exit 1

# Passed to wofi, for -c
w_prompt=""
w_width="25%"
w_height="50%"
w_columns=""
w_lines=""

w_args=()

# Build wofi arguments (w_args) from w_* variables
_constructArgs() {
  w_args=()

  w_args+=("--prompt" "$w_prompt")
  w_args+=("--width" "$w_width")
  w_args+=("--height" "$w_height")

  [[ -n $w_columns ]] && w_args+=("--columns" "$w_columns")
  [[ -n $w_lines ]] && w_args+=("--lines" "$w_lines")
}

while IFS=$'\t' read -r name command; do
  cmd_map["$name"]="$command"
done < <(
  yq -r '.Commands[] | .[] | [.Name, .Command] | @tsv' "$wofi_command_line_data"
)

w_prompt="Select Command" && _constructArgs
choice="$(printf "%s\n" "${!cmd_map[@]}" | sort | wofi -d "${w_args[@]}")"
[[ -z "$choice" ]] && exit 1
eval "${cmd_map["$choice"]}"
exit 0
