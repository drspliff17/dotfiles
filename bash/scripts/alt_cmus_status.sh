#!/usr/bin/env bash

status=$(cmus-remote -Q)

artist=$(echo "$status" | grep '^tag artist ' | cut -d' ' -f3-)
title=$(echo "$status" | grep '^tag title ' | cut -d' ' -f3-)
state=$(echo "$status" | grep '^status ' | cut -d' ' -f2)

if [ "$state" = "playing" ]; then
  icon="▶"
elif [ "$state" = "paused" ]; then
  icon="⏸"
else
  icon="⏹"
fi

text="$icon $artist - $title"

printf '{"text": "%s", "tooltip": "%s"}\n' "$text" "$text"
