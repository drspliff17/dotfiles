#/usr/bin/env bash

LIB_NOTIFY="$HOME/.config/bash/lib/notify.sh"
source "$LIB_NOTIFY" || {
  notify-send -a center-text -t 1500 -u normal "Error" "Could not source required lib: $LIB_NOTIFY"
  exit 1
}

LIB_WOFI="$HOME/.config/bash/lib/wofi_construct.sh"
source "$LIB_WOFI" || {
  _notify -a ct -e -u normal "Could not source required lib: $LIB_WOFI"
  exit 1
}

mode="${1:-window}"
pythonDir="$HOME/dev/python"
mozillaDir="$HOME/.mozilla"

[[ ! -f "$pythonDir/getBookmarks.py" ]] && {
  _notify -a ct -e -t 2000 "Could not find getBookmarks.py"
  exit 1
}

[[ ! -f "$mozillaDir/bookmarks.html" ]] && {
  _notify -a ct -e -t 2000 "Could not find $mozillaDir/bookmarks.html"
  exit 1
}

python "$pythonDir/getBookmarks.py"

entries=()

while IFS=$'\t' read -r title url; do
  entries+=("$title — $url")
done < <(
  jq -r '.[] | [.title, .url] | @tsv' \
    "$mozillaDir/bookmarks.json"
)

WOFI_PROMPT="Select Bookmark To Open (Mode: $mode)"
WOFI_WIDTH="60%"
WOFI_HEIGHT="50%"
w_args=()

_construct w_args

selectedEntry=$(printf '%s\n' "${entries[@]}" | wofi -d "${w_args[@]}")
[[ -z "$selectedEntry" ]] && exit 1

selectedUrl="${selectedEntry#* — }"

url_valid=false
while IFS=$'\t' read -r _ url; do
  [[ "$url" == "$selectedUrl" ]] && {
    url_valid=true
    break
  }
done < <(
  jq -r '.[] | [.title, .url] | @tsv' \
    "$mozillaDir/bookmarks.json"
)

[[ "$url_valid" != true ]] && {
  _notify -a ct -e -t 2000 "Invalid bookmark selected"
  exit 1
}

case "$mode" in
"window" | "w")
  firefox --new-window "$selectedUrl" && exit 0
  ;;

"tab" | "t")
  firefox --new-tab "$selectedUrl" && exit 0
  ;;

*)
  _notify -a ct -e -t 2000 "Invalid mode given: $mode"
  exit 1
  ;;
esac
