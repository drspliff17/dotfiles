#!/usr/bin/env bash

#NOTE: Currently suited for short notifications, as when not TTY, notify-send gets passed the text as it's HEAD argument.
#TODO: Find elegant solution for aforementioned limitation

# Wrapper for sending some notification. Automatically decides whether to pass to stdout or notify-send. Handles own parsing.
_notify() {

  # Defaults
  local d_urgency="low"
  local d_time="1500"
  local urgency time appname message
  local doErr=0

  # Helpers
  _notify_tty() {
    if [[ "$doErr" -eq 0 ]]; then
      echo "$message"
    else
      echo "[ERROR] $message" >&2
    fi
  }

  _notify_send() {
    if [[ "$doErr" -eq 0 ]]; then
      if [[ -z "$appname" ]]; then
        notify-send -u "$urgency" -t "$time" "$message"
      else
        notify-send -u "$urgency" -t "$time" -a "$appname" "$message"
      fi
    else
      if [[ -z "$appname" ]]; then
        notify-send -u "$urgency" -t "$time" "Error" "$message"
      else
        notify-send -u "$urgency" -t "$time" -a "$appname" "Error" "$message"
      fi
    fi
  }

  while [[ "$#" -gt 1 ]]; do
    case "$1" in
    -u)
      shift
      urgency="$1"
      shift
      case "$urgency" in
      low | normal | critical)
        ;;
      l)
        urgency="low"
        ;;
      n)
        urgency="normal"
        ;;
      c)
        urgency="critical"
        ;;
      *)
        urgency="$d_urgency"
        ;;
      esac
      ;;
    -t)
      shift
      time="$1"
      shift
      [[ ! "$time" =~ ^[0-9]+$ ]] && time="$d_time"
      [[ ! "$time" -gt 0 ]] && time="$d_time"
      ;;
    -a)
      shift
      appname="$1"
      shift
      case "$appname" in
      ct | center-text)
        appname="center-text"
        ;;
      ts | theme_selector)
        appname="theme_selector"
        ;;
      vnd | view-notification-details)
        appname="view-notification-details"
        ;;
      nh | no-history)
        appname="no-history"
        ;;
      nhc | nh-center-text)
        appname="nh-center-text"
        ;;
      *)
        appname=""
        ;;
      esac
      ;;
    -e | --error)
      shift
      doErr=1
      ;;
    *)
      #FIX: Make this into an error or something
      shift
      ;;
    esac
  done
  message="$1"
  [[ -z "$message" ]] && return 1

  # TODO: Add custom parsing module here

  if [[ -t 1 ]]; then
    _notify_tty
    return 0
  else
    [[ -z "$urgency" ]] && urgency="$d_urgency"
    [[ -z "$time" ]] && time="$d_time"
    _notify_send
    return 0
  fi
}

#TODO: Make status head injection thing, for which -e / --error will be a shorthand of effectively -s err or something
# _nnotify() {
#   local def_urgency="low" def_time=1500 doError=false
#   local n_args=()
#   local head body message
#
#   local n_appnames=()
#   mapfile -t n_appnames < <(rg app-name= ~/.config/mako/config | cut -d= -f2 | tr -d ']' | sed 's/"//g')
#
#   _addArg() {
#     n_args+=("$1 $2")
#   }
#
#   _validAppname() {
#     for name in "${n_appnames[@]}"; do
#       [[ "$name" = "$1" ]] && _addArg "-a" "$1" && return 0
#       case "$1" in
#       ct) _addArg "-a" "center-text" && return 0 ;;
#       ts) _addArg "-a" "theme_selector" && return 0 ;;
#       vnd) _addArg "-a" "view-notification-details" && return 0 ;;
#       nh) _addArg "-a" "no-history" && return 0 ;;
#       nhc) _addArg "-a" "nh-center-text" && return 0 ;;
#       esac
#     done
#     return 1
#   }
#
#   while [[ "$#" -gt 1 ]]; do
#     case "$1" in
#     -u | --urgency)
#       case "$2" in
#       l | low)
#         _addArg "-u" "low"
#         ;;
#       n | normal)
#         _addArg "-u" "normal"
#         ;;
#       c | critical)
#         _addArg "-u" "critical"
#         ;;
#       *)
#         _addArg "-u" "$def_urgency"
#         ;;
#       esac
#       shift 2
#       ;;
#     -t | --time)
#       [[ ! "$2" =~ ^[0-9]+$ ]] && _addArg "-t" "$def_time" && shift 2 && continue
#       [[ "$2" -le 0 ]] && _addArg "-t" "$def_time" && shift 2 && continue
#       _addArg "-t" "$2"
#       shift 2
#       ;;
#     -a | --appname)
#       if ! _validAppname "$2"; then
#         notify-send -u normal -a center-text "Invalid appname given, skipping inclusion." "Valid names are: [${n_appnames[*]}]"
#         shift 2
#         continue
#       fi
#       # _addArg "-a" "$2"
#       shift 2
#       ;;
#     -i | --icon)
#       _addArg "-i" "$2"
#       shift 2
#       ;;
#     -n | --app-icon)
#       _addArg "-n" "$2"
#       shift 2
#       ;;
#     -e | --error)
#       doError=true
#       shift
#       ;;
#     esac
#   done
#   # Only like this for compat with prev logic
#   head="$1"
#   shift
#
#   if [[ -t 1 ]]; then
#     $doError && head="ERROR $head"
#     echo "$head" && return 0
#   else
#     $doError && head="[ERROR] $head"
#     notify-send "${n_args[@]}" "$head"
#   fi
#
# }
