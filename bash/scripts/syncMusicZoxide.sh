#!/usr/bin/env bash

VERBOSE=0

[[ "$1" = "-v" ]] && VERBOSE=1
ROOT="$HOME/Music/Songs"
ls "$ROOT" | while read line; do
  zoxide query "$line"
  [[ "$?" -eq 1 ]] && {
    zoxide add "$line"
    [[ $VERBOSE -eq 1 ]] && echo "Added $line to zoxide db"
  }
done
echo "[FINISHED]"
