#!/usr/bin/env bash
notify-send -u low -t 1000 -a center-text "Notification History Cleared!"
sleep 1
dunstctl history-clear
