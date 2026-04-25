#!/usr/bin/env bash
pgrep wl-kbptr && exit 1
hyprctl dispatch submap reset
wl-kbptr
