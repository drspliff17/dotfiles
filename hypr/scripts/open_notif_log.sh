#!/usr/bin/env bash

f="/home/drspliff/dev/data/notifications.jsonl"
[[ ! -e "$f" ]] && notify-send -t 2500 -a nhc "No notification log entries" && exit
[[ -z "$(cat "$f")" ]] && notify-send -t 2500 -a nhc "No notification log entries" && rm "$f" && exit
hyprctl dispatch "hl.dsp.exec_cmd(\"kitty fish -c 'n $f'\")"
