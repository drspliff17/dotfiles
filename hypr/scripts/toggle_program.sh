#!/usr/bin/env bash

program="$1"
[[ -z "$program" ]] && exit 1
if pgrep "$program"; then
  killall "$program"
else
  "$program" &
fi
