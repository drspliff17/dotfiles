#!/usr/bin/env bash

nString="
Waiting: $(dunstctl count waiting)
History: $(dunstctl count history)
"
notify-send -u low -t 2500 "Notifications Status" "$nString"
