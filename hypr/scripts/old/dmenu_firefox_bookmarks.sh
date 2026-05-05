#/usr/bin/env bash
mode="$1"
useVi="$2"
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

if [[ -z "$2" ]]; then
  selectedUrl=$(printf '%s\n' "${urls[@]}" | dmenu -c -l 20 -bw 3)
else
  selectedUrl=$(printf '%s\n' "${urls[@]}" | dmenu -c -l 20 -bw 3 -vi)
fi
[[ -z "$selectedUrl" ]] && exit 1

[[ -z "$mode" ]] && mode="window"
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
