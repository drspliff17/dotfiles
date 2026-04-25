#!/usr/bin/env bash
speed="$(grep '^current=' ~/.config/cursor/cursorSpeed | cut -d= -f2)"
notify-send -a center-text -u low -t 1000 "Cursor Speed: $speed"
