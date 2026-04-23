#!/usr/bin/env bash

bash_cpu_wattage() {
  local value="$1"
  local formattedV=""
  local skipPrompt="false"
  local minW=10
  local maxW=90
  [[ -z "$value" ]] && echo "[ERROR] Expected parameter. Usage: <command> [-y to skip conf] <wattage>. Note, wattage must a value between $minW - $maxW." && return 1
  case "$value" in
  -y | --yes)
    shift
    value="$1"
    skipPrompt="true"
    ;;
  esac
  if [[ "$value" =~ ^[0-9]+$ ]] && ((value >= minW && value <= maxW)); then
    formattedV="$value""000"
    if [[ "$skipPrompt" = "false" ]]; then
      read -rp "This will limit CPU Wattage to $value""W Are you sure? [Y/n]:  " confirm
      if [[ ! "$confirm" =~ [Yy] ]]; then
        echo "Aborting CPU Wattage Limit Override" && return 1
      fi
    fi
    sudo ryzenadj -a "$formattedV" -b "$formattedV" -c "$formattedV" && return 0
    echo "[ERROR] Failed to execute" >&2 && return 1
  else
    echo "[ERROR] Invalid wattage given [$value]. Must be between ($minW - $maxW)" >&2 && return 1
  fi
}
