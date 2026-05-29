#/usr/bin/env bash

LIB_NOTIFY="$HOME/.config/bash/lib/notify.sh"
source "$LIB_NOTIFY" || {
  notify-send -a center-text -t 1500 -u normal "Error" "Could not source required lib: $LIB_NOTIFY"
  exit 1
}

mode="select"
count="$(clipvault list | wc -l)"
[[ "$count" -eq 0 ]] && exit 1
case "$1" in
-r | rm | remove)
  shift
  mode="remove"
  ;;
-c | clear)
  shift
  mode="clear"
  ;;
esac

list=$(clipvault list)
thumbnails_dir="${XDG_CACHE_HOME:-$HOME/.cache}/clipvault/thumbs"

[ -d "$thumbnails_dir" ] || mkdir -p "$thumbnails_dir"

find "$thumbnails_dir" -type f | while IFS= read -r thumbnail; do
  item_id=$(basename "${thumbnail%.*}")
  if ! grep -q "^${item_id}\s\[\[ binary data" <<<"$list"; then
    rm "$thumbnail"
  fi
done

read -r -d '' prog <<EOF
/^[0-9]+\s<meta http-equiv=/ { next }
match(\$0, /^([0-9]+)\s\[\[\sbinary.*(jpg|jpeg|png|bmp|webp|tif|gif)/, grp) {
    image = grp[1]"."grp[2]
    system("[[ -f ${thumbnails_dir}/"image" ]] || echo " grp[1] " | clipvault get >${thumbnails_dir}/"image)
    print "text:"grp[1]"\\t:img:$thumbnails_dir/"image
    next
}
1
EOF

case "$mode" in
remove)
  choice="$(gawk <<<"$list" "$prog" | wofi -I --dmenu --prompt "Delete" -Dimage_size=100 -Dynamic_lines=true -d -k /dev/null)"
  [[ -z "$choice" ]] && _notify -a ct "Clipvault is empty!" && exit 0
  echo "$choice" | clipvault delete && _notify -a ct "Clipvault Deleted: $choice"
  exit 0
  ;;
clear)
  clipvault clear && _notify -a ct "Clipvault Cleared" && exit 0
  ;;
select)
  choice=$(gawk <<<"$list" "$prog" | wofi -I --dmenu --prompt "Clipboard" -Dimage_size=100 -Dynamic_lines=true -d -k /dev/null)
  [[ -z "$choice" ]] && _notify -a ct "Clipvault is empty!" && exit 0
  if [ "${choice::5}" = "text:" ]; then
    choice="${choice:5}"
  fi
  echo "$choice" | clipvault get | wl-copy && _notify -a ct "Clipvault Copied: $choice"
  ;;
esac
