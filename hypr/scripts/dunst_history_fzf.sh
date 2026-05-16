#!/usr/bin/env bash

if [[ "$(dunstctl count history)" -eq 0 ]]; then
  notify-send -a center-text -t 1000 -u low "No Notifications To View!"
  sleep 1
  dunstctl history-clear
  exit 1
fi

kitty bash -c '
dunstctl history | jq -r "
  .data[0][] |
  [
    .summary.data,
    .body.data,
    (.appname.data + \" @ \" + (.timestamp.data / 1000000 | strftime(\"%H:%M:%S\")))
  ] | @tsv
" | fzf \
  --delimiter=$'\''\t'\'' \
  --with-nth=1 \
  --preview "printf \"%s\n\n%s\" {3} \"\$(echo -e {2})\"" \
  --preview-window=wrap
'
