#!/usr/bin/env bash

_moveToTarget() {
  local tx="$1"
  local ty="$2"
  read x y <<<"$(hyprctl cursorpos | tr ',' ' ')"

  local dx=$((tx - x))
  local dy=$((ty - y))

  wlrctl pointer move $dx $dy
  return 0
}

_pasteInBox() {
  _moveToTarget 1434 540
  wlrctl pointer click
  ydotool key 29:1 47:1 47:0 29:0
  return 0
}

_copyNvim() {
  _moveToTarget 602 481
  ydotool key 32:1 32:0
  sleep 0.05
  ydotool key 32:1 32:0
  return 0
}

_confirmAndWait() {
  _moveToTarget 1387 632
  wlrctl pointer click
  sleep 3
  wlrctl pointer click
  return 0
}

_loop() {
  _copyNvim
  local t="$(wl-paste)"
  [[ -z "$t" ]] && exit 0
  _pasteInBox
  _confirmAndWait
  _loop
}

_loop
