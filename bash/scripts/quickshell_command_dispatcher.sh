#!/usr/bin/env bash

LIB_NOTIFY="$HOME/.config/bash/lib/notify.sh"
source "$LIB_NOTIFY" || {
  notify-send -u critical -a center-text -t 1500 -u normal "Error" "Could not source required lib: $LIB_NOTIFY"
  exit 1
}

LIB_QS="$HOME/.config/bash/lib/qs.sh"
source "$LIB_QS" || {
  _notify -u c -a ct -e "Could not source required lib: $LIB_QS"
  exit 1
}

_logAppend -t i -m "QS CMD DSP Start"
trap '_logAppend -t i -m "QS CMD DSP Exit"' EXIT

CMD_DISPATCH="$HOME/.config/quickshell/data/cmd_dispatch.json"
CMD_RESPONSE="$HOME/.config/quickshell/data/cmd_response"
CMD_DB="$HOME/.config/quickshell/data/cmd.json"
CONFIG_FILE="$HOME/.config/quickshell/config.json"
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
[[ "$1" = "n" ]] || {
  [[ "$#" -ne "$ARG_COUNT" ]] && {
    _notify -u c -a ct -e "[$CMD_NAME] Invalid argument count provided. Expected: $ARG_COUNT, got $# "
    _logAppend -t e -m "[$CMD_NAME] Invalid argument count provided. Expected: $ARG_COUNT, got $# "
    exit 1
  }
}

# Validate Arg Type, if applicable
ARG_TYPE="$(echo "$MATCH" | jq -r '.arg_type')"
ARG_RAW=("$@")
[[ -n "$ARG_TYPE" ]] && {
  case "$ARG_TYPE" in
  orientation)
    _validateOrientation "$ARG_RAW" || exit 1
    ;;
  esac
}

# Dispatch Command
RESPONSE_EXPECTED="$(echo "$MATCH" | jq -r '.response_expected')"
if [[ "$#" -gt 0 ]]; then
  ARG_JSON="$(
    for arg in "$@"; do
      if jq -e . >/dev/null 2>&1 <<<"$arg"; then
        if jq -e 'type != "string" or startswith("[") or startswith("{")' >/dev/null 2>&1 <<<"$arg"; then
          echo "$arg"
        else
          jq -Rn --arg v "$arg" '$v'
        fi
      else
        jq -Rn --arg v "$arg" '$v'
      fi
    done | jq -s .
  )"
else
  ARG_JSON="[]"
fi

# MANUAL OVERRIDES
case "$CMD_NAME" in
"get_configProperty")
  jq -r ".$ARG_JSON" "$CONFIG_FILE" && exit 0
  _notify -a ct -e "Failed to find key: $ARG_JSON" && exit 1
  ;;
esac

TS=$(date +%s%3N)
jq -n \
  --arg command "$CMD_NAME" \
  --arg ts "$TS" \
  --argjson args "$ARG_JSON" \
  '{ts: $ts, command: $command, args: $args, response: ""}' >"$TMP_FILE"

mv "$TMP_FILE" "$CMD_DISPATCH" && _logAppend -t i -m "Dispatch Created: $CMD_NAME : ${ARG_RAW[*]}"
sleep 0.2
echo "{}" >"$CMD_DISPATCH" && _logAppend -t i -m "Dispatch Cleared"

# Check for response and do a thing
[[ ! "$RESPONSE_EXPECTED" = "true" ]] && {
  exit 0
}
[[ ! -f "$CMD_RESPONSE" ]] && {
  _notify -u c -a ct -e "Reponse expected but file not found!"
  _logAppend -t e -m "$CMD_NAME failed: Reason: Expected cmd response not found"
  exit 1
}
RESPONSE="$(cat "$CMD_RESPONSE")"
_logAppend -t i -m "Received Response: $RESPONSE"
echo "$RESPONSE"
rm "$CMD_RESPONSE" && exit 0

#TODO: Potentially add post command, response based action here, maybe eval a cmd string from cmd database?
