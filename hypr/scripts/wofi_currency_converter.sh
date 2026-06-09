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
CACHE="$HOME/.config/wofi/state/currencyCache.json"
SOURCE_CUR=""
TARG_CUR=""
AMOUNT_CUR=""
VALID_CURS=()
CONVERTED=""

_test_time() {
  local t="$1" hours minutes seconds
  [[ -z "$t" ]] && return 1
  hours=$((t / 3600))
  minutes=$(((t % 3600) / 60))
  seconds=$((t % 60))
  _notify -a ct "$t was ${hours}h ${minutes}m ${seconds}s ago" && return 0
}

# Checks if time elapsed since last _cacheData call is greater than threshold. Returns bool value
_calculateTS_Diff() {
  [[ ! -f "$CACHE" ]] && return 0
  local now cache diff
  local threshold=43250 #12 hours 3 mins ish or some shit
  now=$(date +%s)
  cache=$(jq -r '.timestamp // 0' "$CACHE")
  diff=$((now - cache))
  if ((diff < threshold)); then
    return 1
  fi
  return 0
}

# Handle prompt for calling _cacheData. Returns bool value
_promptCache() {
  local hours minutes seconds confirm

  hours=$((diff / 3600))
  minutes=$(((diff % 3600) / 60))
  seconds=$((diff % 60))

  if [[ -t 1 ]]; then
    read -rp \
      "Last cached ${hours}h ${minutes}m ${seconds}s ago. Confirm recache [Y/n]: " \
      confirm
  else
    _wofiConfirmationPrompt -m "Confirm recache?" || return 1
    confirm="Y"
  fi

  case "$confirm" in
  Y | y) return 0 ;;
  *) return 1 ;;
  esac
}

# Curl latest conversion data, store in $CACHE
_cacheData() {
  local ts="$(date +%s)"
  curl -s https://api.fxratesapi.com/latest >"$CACHE" || {
    _notify -a ct -e "Failed to cache fxratesapi/latest" && return 1
  }
  local tmp=$(mktemp)
  jq --argjson t "$ts" '.timestamp = $t' "$CACHE" >"$tmp" && mv "$tmp" "$CACHE"

  _notify -a ct "Cached fxratesapi/latest to $CACHE" && return 0
}

# Main conversion logic, using main vars
_doConversion() {
  local from="$1"
  local to="$2"
  local amount="$3"
  CONVERTED="$(curl -s --request GET --url "https://api.fxratesapi.com/convert?from=$from&to=$to&amount=$amount&format=json")"
  return 0
}

# Logic for interactive argument prompt menu
_loopPrompt() {
  local mode="init" w_args selection amt_str
  while true; do
    case "$mode" in
    init)
      [[ "${#VALID_CURS[@]}" -eq 0 ]] && return 1
      mode="main" && continue
      ;;

    main)
      [[ -z "$SOURCE_CUR" ]] && mode="set_src" && continue
      [[ -z "$TARG_CUR" ]] && mode="set_trg" && continue
      [[ -z "$AMOUNT_CUR" ]] && mode="set_amt" && continue
      return 0
      ;;

    set_src)
      _wofiConstructFromArgs w_args -p "Select Starting Currency" -w "15%" -h "40%" -cf "$WOFI_C_CENTER"
      selection="$(printf '%s\n' "${VALID_CURS[@]}" | wofi -d -E "${w_args[@]}")"
      [[ -z "$selection" ]] && return 1
      SOURCE_CUR="$selection" && mode="main" && continue
      ;;

    set_trg)
      _wofiConstructFromArgs w_args -p "Select Target Currency" -w "15%" -h "40%" -cf "$WOFI_C_CENTER"
      selection="$(printf '%s\n' "${VALID_CURS[@]}" | wofi -d -E "${w_args[@]}")"
      [[ -z "$selection" ]] && return 1
      TARG_CUR="$selection" && mode="main" && continue
      ;;

    set_amt)
      amt_str="($SOURCE_CUR -> $TARG_CUR)"
      _wofiConstructFromArgs w_args -p "Enter Amount" -w "15%" -h "5%" -l 1 -cf "$WOFI_C_CENTER"
      selection="$(echo "$amt_str" | wofi -d "${w_args[@]}")"
      [[ -z "$selection" ]] && return 1
      [[ ! "$selection" =~ ^[0-9]+(\.[0-9]+)?$ ]] && return 1
      AMOUNT_CUR="$selection" && mode="main" && continue
      ;;
    esac
  done
}

_validateArg() {
  local type="$1" arg="$2"
  [[ -z "$type" || -z "$arg" ]] && return 1
  case "$type" in
  cur)
    for c in "${VALID_CURS[@]}"; do
      [[ "$c" = "$arg" ]] && return 0
    done
    return 1
    ;;

  amt)
    [[ "$arg" =~ ^[0-9]+(\.[0-9]+)?$ ]] && return 0
    return 1
    ;;
  *)
    return 1
    ;;
  esac
}

# Main

if _calculateTS_Diff; then
  _cacheData
fi
mapfile -t VALID_CURS < <(jq -r '.rates | keys_unsorted[]' "$CACHE")

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -u | --upd | update)
    MODE="update"
    shift
    ;;

  -s | --src | source)
    _validateArg "cur" "$2" || {
      _notify -a ct -e "Source: Invalid Currency Given: $SOURCE_CUR"
      exit 1
    }
    SOURCE_CUR="$2"
    shift 2
    ;;

  -t | --trg | target)
    _validateArg "cur" "$2" || {
      _notify -a ct -e "Target: Invalid Currency Given: $TARG_CUR"
      exit 1
    }
    TARG_CUR="$2"
    shift 2
    ;;

  -a | --amt | amount)
    _validateArg "amt" "$2" || {
      _notify -a ct -e "Amount: Invalid Currency Given: $AMOUNT_CUR"
      exit 1
    }
    AMOUNT_CUR="$2"
    shift 2
    ;;

  -*)
    _notify -a ct -e "Unrecognized argument: $1" && exit 1
    ;;

  *)
    _notify -a ct -e "Unrecognized option: $1" && exit 1
    ;;
  esac
done

[[ -z "$MODE" ]] && MODE="prompt"
case "$MODE" in
prompt)
  _loopPrompt || exit 1
  _doConversion "$SOURCE_CUR" "$TARG_CUR" "$AMOUNT_CUR"
  CONVERTED="$(echo "$CONVERTED" | jq '.result')"
  CONVERTED="$(printf '%.2f\n' "$CONVERTED")"
  _notify -a ct -t 2500 "💸 $AMOUNT_CUR [$SOURCE_CUR] ➡️ $CONVERTED [$TARG_CUR] 💰" && wl-copy "$CONVERTED" && exit 0
  ;;
update)
  _promptCache && _cacheData
  exit 0
  ;;
esac
