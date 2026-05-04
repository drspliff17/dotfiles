#!/usr/bin/env bash

bash_mangolauncher() {
  local key="$1"
  [[ -z "$key" ]] && echo "[ERROR] Expected key: usage <command> <key>" && return 1

  local data="$HOME/stuff/mangohud_stuff/mangohud_launcher_data.yml"
  [[ ! -f "$data" ]] && echo "[ERROR] Could not find data at expected path [$data]" && return 1

  mapfile -t matches < <(yq -r --arg key "$key" '
  .entries[]
  | select(.keys[] == $key)
  | .path
  ' "$data")

  if ((${#matches[@]} == 0)); then
    echo "[ERROR] No match for key [$key]"
    return 1
  elif ((${#matches[@]} > 1)); then
    echo "[ERROR] Multiple matches for key [$key]:"
    printf ' - %s\n' "${matches[@]}"
    return 1
  fi

  local path="${matches[0]}"
  mangohud "$path" && return 0
  echo "[ERROR] Failed to launch" >&2 && return 1
}
