#!/usr/bin/env bash

posX="$1"
posY="$2"
[[ -z "$posX" ]] && posX=0
[[ -z "$posY" ]] && posY=0
[[ "$posX" -eq 0 && "$posY" -eq 0 ]] && exit 1
[[ ! "$posX" =~ ^-?[0-9]+$ || ! "$posY" =~ ^-?[0-9]+$ ]] && exit 1

speed="$(grep '^current=' ~/.config/cursor/cursorSpeed | cut -d= -f2)"
[[ -z "$speed" ]] && speed=50

posX=$((posX * speed))
posY=$((posY * speed))

curPos="$(hyprctl cursorpos)"
cx="${curPos%,*}"
cy="${curPos#*,}"
cy="$(echo "$cy" | xargs)"
nx=$((cx + posX))
ny=$((cy + posY))

#hyprctl dispatch movecursor "$nx" "$ny" >/dev/null && exit 0 || exit 1
hyprctl dispatch "hl.dsp.cursor.move({ x = "$nx", y = "$ny"})" >/dev/null && exit 0 || exit 1
