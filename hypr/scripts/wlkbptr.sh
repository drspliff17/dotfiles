#!/usr/bin/env bash
pgrep wl-kbptr && exit 1
hyprctl dispatch 'hl.dsp.submap("reset")'
wl-kbptr && hyprctl dispatch 'hl.dsp.submap("Cursor")'
