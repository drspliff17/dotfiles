#!/usr/bin/env bash

declare -A seen
declare -A duplicates

ROOT="$HOME/Music/Songs"

normalize() {
  local s="$1"

  s="${s##*/}"  # basename
  s="${s%.mp3}" # remove extension
  s="${s,,}"    # lowercase

  # remove all separators/punctuation
  s="$(sed 's/[^a-z0-9]//g' <<<"$s")"

  echo "$s"
}

process_dir() {
  local DIR="$1"

  seen=()
  duplicates=()

  shopt -s nullglob

  for file in "$DIR"/*.mp3; do
    [[ ! -f "$file" ]] && continue

    normalized="$(normalize "$file")"

    if [[ -n "${seen[$normalized]:-}" ]]; then

      if [[ -z "${duplicates[$normalized]:-}" ]]; then
        duplicates["$normalized"]="${seen[$normalized]}"
      fi

      duplicates["$normalized"]+=$'\n'"$file"

    else
      seen["$normalized"]="$file"
    fi
  done

  [[ ${#duplicates[@]} -eq 0 ]] && {
    echo "[OK] No duplicates in: $DIR"
    return
  }

  echo
  echo "Duplicates detected in: $DIR"
  echo

  for key in "${!duplicates[@]}"; do
    echo "=== $key ==="
    printf '%s\n' "${duplicates[$key]}"
    echo
  done

  read -rp "Remove duplicates in this folder? [Y/n]: " confirm
  [[ ! "$confirm" =~ ^[Yy]$ ]] && return

  for key in "${!duplicates[@]}"; do

    echo
    echo "Match found:"

    mapfile -t files <<<"${duplicates[$key]}"

    for i in "${!files[@]}"; do
      printf '[%d] %s\n' "$((i + 1))" "${files[$i]}"
    done

    echo
    read -rp "Enter numbers to delete: " selections
    [[ -z "$selections" ]] && continue

    for sel in $selections; do
      [[ ! "$sel" =~ ^[0-9]+$ ]] && continue

      index=$((sel - 1))
      [[ $index -lt 0 || $index -ge ${#files[@]} ]] && continue

      rm -- "${files[$index]}"
    done
  done
}

# MAIN

[[ ! -d "$ROOT" ]] && {
  echo "[ERROR] Missing root: $ROOT"
  exit 1
}

for DIR in "$ROOT"/*/; do
  [[ -d "$DIR" ]] || continue
  process_dir "$DIR"
done

echo "[DONE]"
