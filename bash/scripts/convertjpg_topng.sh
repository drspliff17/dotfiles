#!/usr/bin/env bash

TARG="$1"
[[ -z "$TARG" ]] && {
  read -rp "Enter Target Directory: " dir
  [[ -z "$dir" ]] && echo "Target Dir Required." >&2 && exit 1
  TARG="$dir"
}

[[ ! -d "$TARG" ]] && echo "Invalid Directory" >&2 && exit 1

shopt -s nullglob

JPG=(*.jpg)

shopt -u nullglob

count="${#JPG[@]}"
[[ $count -eq 0 ]] && echo "No .jpg / .jpeg files found in $TARG" >&2 && exit 1

for file in "${JPG[@]}"; do
  base="${file%.jpg}"
  mv "$file" "$base.png"
done
echo "Converted $count jpg into png files at: $TARG"
