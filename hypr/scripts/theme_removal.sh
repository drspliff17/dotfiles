#!/usr/bin/env bash

dir="${1:-$PWD}"
ext="${2:-.png}"
[[ ! -d "$dir" ]] && echo "Expected Directory To Scan" >&2 && exit 1

shopt -s nullglob
FILES=("$dir"/*"$ext")
shopt -u nullglob

[[ "${#FILES[@]}" -eq 0 ]] && echo "No files matching $ext in $dir" && exit
selection="$(printf '%s\n' "${FILES[@]}" | nsxiv -toi)" || exit 1
[[ -z "$selection" ]] && echo "No files selected" && exit
mapfile -t selected <<<"$selection"

printf 'Following files selected\n'
printf '%s\n' "${selected[@]}"

read -rp "Deleted ${#selected[@]} files: [Y/n] " conf
if [[ "$conf" =~ ^[yY]$ ]]; then
  rm -v -- "${selected[@]}"
else
  echo "Aborted" && exit
fi
