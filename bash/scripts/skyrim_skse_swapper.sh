#!/usr/bin/env bash

LIB_NOTIFY="$HOME/.config/bash/lib/notify.sh"
source "$LIB_NOTIFY" || {
  notify-send -t 1500 -u low -a center-text "[ERROR] Failed to source bash/lib/notify"
  exit 1
}

SKYRIM_DIR="/storage/steamGames/steamapps/common/Skyrim"

LAUNCHER="$SKYRIM_DIR/SkyrimLauncher.exe.backup"
SKSE="$SKYRIM_DIR/skse_loader.exe"
LINK="$SKYRIM_DIR/SkyrimLauncher.exe"
SKIP=0
[[ ! -e "$LINK" ]] && ln -sf "$LAUNCHER" "$LINK" && _notify -a ct "[SKYRIM] Defaulted To Launcher ⚔️" && exit 0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -g | get) SKIP=1 && shift ;;
  *) shift ;;
  esac
done

case "$(readlink "$LINK")" in
"$LAUNCHER")
  [[ "$SKIP" -eq 1 ]] && _notify -a ct "[SKYRIM] Currently: Launcher ⚔️" && exit 0
  ln -sf "$SKSE" "$LINK" && _notify -a ct "[SKYRIM] Set SKSE Bypass ⚔️" && exit 0
  ;;

"$SKSE")
  [[ "$SKIP" -eq 1 ]] && _notify -a ct "[SKYRIM] Currently: SKSE ⚔️" && exit 0
  ln -sf "$LAUNCHER" "$LINK" && _notify -a ct "[SKYRIM] Set Original Launcher ⚔️" && exit 0
  ;;

*)
  _notify -a ct -e "Invalid Link, you fucked up lol" && exit 1
  ;;
esac
