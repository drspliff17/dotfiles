#!/usr/bin/env bash

mode="$1"
value="$2"
cspeedFile="$HOME/.config/cursor/cursorSpeed"

while IFS='=' read -r key val; do
  case "$key" in
  current) current="$val" ;;
  min) min="$val" ;;
  max) max="$val" ;;
  esac
done <"$cspeedFile"

[[ -z "$current" ]] && current=50
[[ -z "$min" ]] && min=1
[[ -z "$max" ]] && max=1000

[[ -z "$mode" ]] && exit 1
[[ ! "$value" =~ ^-?[0-9]+$ || "$value" -eq 0 ]] && exit 1

case "$mode" in
-s | set)
  new="$value"
  ;;
-i | increase)
  new=$((current + value))
  ;;
-d | decrease)
  new=$((current - value))
  ;;
*)
  exit 1
  ;;
esac

((new < min)) && new="$min"
((new > max)) && new="$max"

cat >"$cspeedFile" <<EOF
current=$new
min=$min
max=$max
EOF
exit 0
