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
