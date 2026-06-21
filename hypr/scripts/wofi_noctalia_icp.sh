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

MODE=""
DATA="$HOME/dev/data/noctalia"
RAW_ICP="$DATA/noctalia_ipc_list.txt"
ICP_TARGETS="$DATA/noctalia_ipc_targets.txt"

_initData() {
  mkdir -p "$DATA"
  [[ ! -f "$RAW_ICP" ]] && {
    qs -c noctalia-shell ipc show >"$RAW_ICP"
    _notify -a nhc -u low "[INFO] Created $RAW_ICP"
  }
  [[ ! -f "$ICP_TARGETS" ]] && {
    _getTargets
    _notify -a nhc -u low "[INFO] Created $ICP_TARGETS"
  }
}

_getTargets() {
  awk '$1 == "target" { print $2 }' "$RAW_ICP" >"$ICP_TARGETS"
}

_getFunctions() {
  local target="$1"

  awk -v target="$target" '
$1 == "target" {
in_target = ($2 == target)
next
}
in_target && /^[[:space:]]*function / {
sub(/^[[:space:]]*function /, "")
print
}
' "$RAW_ICP"
}

_getFuncArgs() {
  local sig="$1"
  local args

  args="${sig#*(}"
  args="${args%%)*}"

  [[ -z "$args" ]] && return 0

  tr ',' '\n' <<<"$args" | sed 's/^ *//'
}

_parseFuncName() {
  local sig="$1"
  echo "${sig%%(*}"
}

_initData

ipcTarget=""

mapfile -t targets <"$ICP_TARGETS"

w_args=()
_wofiConstructFromArgs w_args -p "Pick IPC Target" -w "15%" -cf "$WOFI_C_CENTER"
selection="$(printf '%s\n' "${targets[@]}" | wofi -d -E "${w_args[@]}")"
[[ -z "$selection" ]] && exit 1

ipcTarget="$selection"

_wofiConstructFromArgs w_args -p "Pick $selection Function" -w "50%" -cf "$WOFI_C_CENTER"
func_full="$(_getFunctions "$selection" | wofi -d -E "${w_args[@]}")"
[[ -z "$func_full" ]] && exit 1

func_name="$(_parseFuncName "$func_full")"

mapfile -t args < <(_getFuncArgs "$func_full")

values=()

for arg in "${args[@]}"; do
  _wofiConstructFromArgs w_args -p "Enter Arg for $arg"
  _notify -a nhc -u low -t 3000 "$arg"
  value="$(wofi -d "${w_args[@]}")"
  [[ -z "$value" ]] && continue
  values+=("$value")
done

qs -c noctalia-shell ipc call "$ipcTarget" "$func_name" "${values[@]}"
