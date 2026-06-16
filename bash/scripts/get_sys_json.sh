#!/usr/bin/env bash

MODE="$1"

case "$MODE" in
-c | --cpu | cpu)
  ctemp="$(sensors | awk ' /Tctl:/ {gsub(/[+°C]/,"",$2); print int($2); exit} /Tdie:/ {gsub(/[+°C]/,"",$2); print int($2); exit} ')"
  jq -nc --arg t "$ctemp" '{text:$t}'
  exit 0
  ;;
-g | --gpu | gpu)
  gtemp="$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null)"
  jq -nc --arg t "$gtemp" '{text:$t}'
  exit 0
  ;;
-r | --ram | ram)
  total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
  if ((available >= 1048576)); then
    available_hr=$(awk -v a="$available" 'BEGIN { printf "%.1f GB", a/1024/1024 }')
  else
    available_hr=$(awk -v a="$available" 'BEGIN { printf "%.0f MB", a/1024 }')
  fi

  used_percent=$(awk -v t="$total" -v a="$available" 'BEGIN { printf "%.0f", 100*(t-a)/t }')
  formatted=$(printf "%02d" "$used_percent")
  jq -nc --arg f "$formatted" '{text:$f}'
  exit 0
  ;;
*)
  echo "INVALID MODE" >&2 && exit 1
  ;;
esac
