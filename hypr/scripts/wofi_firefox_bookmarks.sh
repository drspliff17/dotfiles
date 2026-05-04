#/usr/bin/env bash
mode="$1"
pythonDir="$HOME/dev/python"
mozillaDir="$HOME/.mozilla"

[[ ! -d "$pythonDir" ]] && {
  mkdir -p "$pythonDir"
  notify-send -u low -t 1000 "Created $pythonDir"
}

[[ ! -f "$pythonDir/getBookmarks.py" ]] && {
  notify-send -u low -t 2000 "Error" "Could not find get getBookmarks.py" && exit 1
}

[[ ! -d "$mozillaDir" ]] && {
  notify-send -u low -t 2000 "Error" "Could not find $mozillaDir" && exit 1
}

[[ ! -f "$mozillaDir/bookmarks.html" ]] && {
  notify-send -u low -t 2000 "Error" "Could not find bookmarks.html"
}

python "$pythonDir/getBookmarks.py"

mapfile -t urls < <(jq -r '.[].url' "$mozillaDir/bookmarks.json")
[[ -z "$mode" ]] && mode="window"

# Passed to wofi
w_prompt="Select Bookmark To Open (Mode: $mode)"
w_width="60%"
w_height="50%"
w_columns=""
w_lines=""

w_args=()

# Build wofi arguments (w_args) from w_* variables
_constructArgs() {
  w_args=()

  w_args+=("--prompt" "$w_prompt")
  w_args+=("--width" "$w_width")
  w_args+=("--height" "$w_height")

  [[ -n $w_columns ]] && w_args+=("--columns" "$w_columns")
  [[ -n $w_lines ]] && w_args+=("--lines" "$w_lines")
}

_constructArgs
selectedUrl=$(printf '%s\n' "${urls[@]}" | wofi -d "${w_args[@]}")
[[ -z "$selectedUrl" ]] && exit 1

case "$1" in
"window" | "w")
  firefox --new-window "$selectedUrl" && exit 0
  ;;

"tab" | "t")
  firefox --new-tab "$selectedUrl" && exit 0
  ;;
*)
  notify-send -u low -t 2000 "Error" "Invalid mode given: $mode" && exit 1
  ;;
esac
