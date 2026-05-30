#!/usr/bin/env bash

# NOTE: Depends on ~/.config/bash/lib/notify.sh

QS_LOG="$HOME/.config/quickshell/data/log"
QS_LOG_LIMIT=3000

[[ "$(cat "$QS_LOG" | wc -l)" -gt "$QS_LOG_LIMIT" ]] && {
  tail -n +1500 "$QS_LOG" >"$QS_LOG.tmp" && mv "$QS_LOG.tmp" "$QS_LOG"
  _notify -a ct "Pruned log file: $QS_LOG"
}
[[ ! -f "$QS_LOG" ]] && touch "$QS_LOG" && _notify -a ct "Created log file: $QS_LOG"

_validateOrientation() {
  case "$1" in
  left | right | top | bottom)
    return 0
    ;;
  *)
    _notify -a ct -e "Invalid orientation given. Valid = < top bottom left right >"
    _logAppend -t e -m "$CMD_NAME failed: Reason: _validateOrientation failed check"
    return 1
    ;;
  esac
}

_logAppend() {
  [[ -z "$1" ]] && _notify -a ct -e "_logAppend: Requires message, you spoon." && return 1
  local type msg ts
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
    -t | type)
      shift
      type="$1"
      shift
      case "$type" in
      e | error)
        type="[ERROR]"
        ;;
      w | warn)
        type="[WARNING]"
        ;;
      i | info)
        type="[INFO]"
        ;;
      *)
        _notify -a ct -e "_logAppend: Invalid type given, you spoon." && return 1
        ;;
      esac
      ;;
    -m | msg)
      shift
      msg="$1"
      shift
      ;;
    esac
  done
  [[ -z "$msg" ]] && _notify -a ct -e "_logAppend: Message required, duh!" && return 1
  [[ -z "$type" ]] && type="[ERROR]"
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[ $ts ] >>> $type: $msg" >>"$QS_LOG"
  return 0
}
