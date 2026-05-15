#!/usr/bin/env bash
LIB_NOTFIY="$HOME/.config/bash/lib/notify.sh"
source "$LIB_NOTFIY" >/dev/null || {
  notify-send -a center-text -t 1500 -u critical "Error" "Failed to source lib: $LIB_NOTFIY" && exit 1
}

VERBOSE=0
[[ "$1" = "-v" ]] && VERBOSE=1
ROOT="$HOME/Music/Songs"
ls "$ROOT" | while read line; do
  zoxide query "$line" >/dev/null
  [[ "$?" -eq 1 ]] && {
    zoxide add "$line"
    [[ $VERBOSE -eq 1 ]] && _notify "Added $line to zoxide db"
  }
done
_notify -a ct "Sync Complete"
