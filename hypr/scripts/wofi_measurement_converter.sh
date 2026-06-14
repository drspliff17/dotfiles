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

DB="$HOME/dev/data/convert_units.json"

_convert() {
  local category="$1"
  local from="$2"
  local to="$3"
  local value="$4"

  jq -n \
    --arg cat "$category" \
    --arg from "$from" \
    --arg to "$to" \
    --argjson val "$value" \
    --slurpfile db "$DB" '
      ($db[0][$cat] // {}) as $u
      | $u[$from] as $f
      | $u[$to] as $t
      | if ($f == null or $t == null)
        then "invalid unit"
        else ($val * $f / $t)
        end
    '
}

_pick_category() {
  local w_args=()
  local count="$(jq -r 'length' "$DB")"
  [[ "$count" -ge 10 ]] && count=10
  _wofiConstructFromArgs w_args -p "Pick Category" -w "10%" -l "$count" -cf "$WOFI_C_CENTER"
  jq -r 'keys[]' "$DB" | wofi -d -E "${w_args[@]}"
}

_pick_unit() {
  local cat="$1"
  local w_args=()
  local count="$(jq -r --arg c "$cat" '.[$c] | length' "$DB")"
  [[ "$count" -ge 10 ]] && count=10
  _wofiConstructFromArgs w_args -p "$2:" -w "10%" -l "$count" -cf "$WOFI_C_CENTER"
  jq -r --arg c "$cat" '.[$c] | keys[]' "$DB" |
    wofi -d -E "${w_args[@]}"
}

_pick_value() {
  local w_args=()
  local f="$1" t="$2"
  _wofiConstructFromArgs w_args -p "Convert: $f ➡️ $t" -w "15%" -l 1 -cf "$WOFI_C_CENTER"
  echo -e " " | wofi -d "${w_args[@]}"
}

_main() {
  local category from to value result

  category="$(_pick_category)" || exit 1
  [ -z "$category" ] && exit 0

  from="$(_pick_unit "$category" "From")" || exit 1
  [ -z "$from" ] && exit 0

  to="$(_pick_unit "$category" "To")" || exit 1
  [ -z "$to" ] && exit 0

  value="$(_pick_value "$from" "$to")" || exit 1
  [ -z "$value" ] && exit 0

  result="$(_convert "$category" "$from" "$to" "$value")"

  if [[ "$result" == "invalid unit" ]]; then
    _notify -a ct -e -u normal "Conversion failed" "Unknown unit"
    exit 1
  fi

  _notify -a ct -t 3000 "Conversion" "$value $from ➡️ $result $to"
  echo "$result" | wl-copy
}

_main "$@"
