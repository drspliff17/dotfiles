#!/usr/bin/env bash

LIB_NOTIFY="$HOME/.config/bash/lib/notify.sh"
source "$LIB_NOTIFY" || {
  notify-send -a center-text -t 1500 -u normal "Error" "Could not source required lib: $LIB_NOTIFY"
  exit 1
}

LIB_QS="$HOME/.config/bash/lib/qs.sh"
source "$LIB_QS" || {
  _notify -a ct -e "Could not source required lib: $LIB_QS"
  exit 1
}

CMD_DISPATCH="$HOME/.config/quickshell/data/cmd_dispatch.json"
CMD_DB="$HOME/.config/quickshell/data/cmd.json"
TMP_FILE="$(mktemp)"

# Grab command from CMD_DB
INPUT="$1"
[[ -z "$INPUT" ]] && exit 1
shift

MATCH="$(jq -c --arg cmd "$INPUT" '
  .[] | select(.alias | index($cmd))
' "$CMD_DB")"

[[ -z "$MATCH" ]] && exit 1

# Validate Arg Count
CMD_NAME="$(echo "$MATCH" | jq -r '.command')"
ARG_COUNT="$(echo "$MATCH" | jq -r '.arg_count')"
[[ "$#" -ne "$ARG_COUNT" ]] && exit 1

# Validate Arg Type, if applicable
ARG_TYPE="$(echo "$MATCH" | jq -r '.arg_type')"
ARG_RAW=("$@")
[[ -n "$ARG_TYPE" ]] && {
  case "$ARG_TYPE" in
  orientation)
    _validateOrientation "$ARG_RAW" || {
      _notify -a ct -e "Invalid orientation given. Valid = < top bottom left right >"
      exit 1
    }
    ;;
  esac
}

if [[ "$#" -gt 0 ]]; then
  ARG_JSON="$(printf '%s\n' "$@" | jq -R . | jq -s .)"
else
  ARG_JSON="[]"
fi

TS=$(date +%s%3N)
jq -n \
  --arg command "$CMD_NAME" \
  --arg ts "$TS" \
  --argjson args "$ARG_JSON" \
  '{ts: $ts, command: $command, args: $args}' >"$TMP_FILE"

mv "$TMP_FILE" "$CMD_DISPATCH"
sleep 0.2
echo "{}" >"$CMD_DISPATCH"
