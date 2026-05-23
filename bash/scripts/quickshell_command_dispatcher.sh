#!/usr/bin/env bash

CMD_DISPATCH="$HOME/.config/quickshell/data/cmd_dispatch.json"
CMD_DB="$HOME/.config/quickshell/data/cmd.json"
TMP_FILE="$(mktemp)"

INPUT="$1"
[[ -z "$INPUT" ]] && exit 1
shift

MATCH="$(jq -c --arg cmd "$INPUT" '
  .[] | select(.alias | index($cmd))
' "$CMD_DB")"

[[ -z "$MATCH" ]] && exit 1

CMD_NAME="$(echo "$MATCH" | jq -r '.command')"
ARG_COUNT="$(echo "$MATCH" | jq -r '.arg_count')"

[[ "$#" -ne "$ARG_COUNT" ]] && exit 1

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
