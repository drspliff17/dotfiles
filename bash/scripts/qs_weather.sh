#!/usr/bin/env bash

MODE="${1:-default}"
RESPONSE=""

_makeRequest() {
  curl -s wttr.in?format=$1
}

_respond() {
  [[ -z "$RESPONSE" ]] && exit 1
  echo "$RESPONSE" && exit 0
}

trap '_respond' EXIT

case "$MODE" in
default | 1)
  RESPONSE="$(_makeRequest 1)"
  ;;
wind | 2)
  RESPONSE="$(_makeRequest 2)"
  RESPONSE="$(echo "$RESPONSE" | cut -d ' ' -f 4)"
  ;;
esac
