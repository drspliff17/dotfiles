#!/usr/bin/env bash

which git-lfs || echo -e "[ERROR] Could not find dependancy: git-lfs\nInstall and try again" >&2 && exit 1

WD="$PWD"
DST="$HOME/Odin"
SL="/usr/local/bin"

while [[ "$#" -gt 0 ]]; do
  case "$1" in

  -d | --dest | dest | destinaton)
    DST="$2"
    [[ ! -d "$(dirname "$DST")" ]] && echo "[ERROR] Expected $(dirname "$DST") to exist" >&2 && exit 1
    shift 2
    ;;
  -l | --link | link)
    SL="$2"
    [[ ! -d "$SL" ]] && echo "[ERROR] Invalid Directory for link: $DST" >&2 && exit 1
    shift 2
    ;;

  *) echo "[ERROR] Invalid argument: $1" >&2 && exit 1 ;;

  esac
done

read -rp "Enter Mode ([b]uild / [u]pgrade) *default = build: " MODE
case "$MODE" in
u | upgrade) MODE="upgrade" ;;
*) MODE="build" ;;
esac

case "$MODE" in

build)
  [[ -d "$DST" ]] && echo "[ERROR] Directory already exists at target: $DST" >&2 && exit 1
  [[ ! -d "$(dirname "$DST")" ]] && echo "[ERROR] Directory path is invalid" >&2 && exit 1

  echo "Building now ..."

  cd "$(dirname "$DST")"
  git clone https://github.com/odin-lang/Odin.git || {
    echo "[ERROR] Failed to clone!" >&2 && exit 1
  }
  cd "$DST"

  git lfs install
  git lfs pull

  make release

  ln -s "$DST/odin" "$SL/odin"
  cd "$WD" && exit 0

  ;;

upgrade)
  [[ ! -d "$DST" ]] && echo "[ERROR] Could not find path: $DST" >&2 && exit 1

  read -rp "Would you like to run 'make clean'? [N/y]: " DOCLEAN
  [[ -z "$DOCLEAN" ]] && DOCLEAN=0
  case "$DOCLEAN" in
  Y | y | yes) DOCLEAN=1 ;;
  *) DOCLEAN=0 ;;
  esac

  echo "Upgrading now ..."

  cd "$DST"
  git pull
  git lfs pull

  [[ "$DOCLEAN" -eq 1 ]] && make clean
  make release

  [[ -e "$SL" ]] && rm "$SL"
  ln -s "$DST/odin" "$SL/odin"
  cd "$WD" && exit 0

  ;;

esac
