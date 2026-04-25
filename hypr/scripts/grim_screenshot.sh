#!/usr/bin/env bash

scrPath="$HOME/Pictures/Screenshots"
scrFilename=$(date +'%Y-%m-%d_%H-%M-%S').png
case "$1" in
s | slurp)
  grim -g "$(slurp)" -c "$scrPath/$scrFilename" && notify-send -u low -t 1000 -a center-text "Screenshot taken" "File Name: $scrFilename"
  ;;

g | global)
  grim -c "$scrPath/$scrFilename" && notify-send -u low -t 1000 -a center-text "Screenshot taken" "File Name: $scrFilename"
  ;;
esac
