#!/usr/bin/env bash

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

LIB_TODO="$HOME/.config/bash/lib/todo_tool.sh"
source "$LIB_TODO" || {
  _notify -a ct -e -u normal "Could not source required lib: $LIB_TODO"
  exit 1
}

ROOT_DIR="$HOME/.local/share/todo_tool"
LOG_DIR="$ROOT_DIR/logs"
ENTRY_DIR="$ROOT_DIR/data"
BACKUP_DIR="$ROOT_DIR/backups"
DB="$ROOT_DIR/manifest.yml"

MODE=""
TARGETS=()

if ! _foundFiles; then
  _init || {
    _notify -e -a ct "Todo Tool Setup Failed!"
    exit 1
  }
  _notify -a ct "Todo Tool Setup Complete!"
fi

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -h | help)
    #TODO: Add help message here
    ;;
  -a | add)
    shift
    MODE="ADD"
    TITLE="$1"
    shift
    ;;
  -d | delete)
    shift
    MODE="DELETE"
    while [[ "$#" -gt 0 ]]; do
      TARGETS+=("$1")
      shift
    done
    break
    ;;
  -e | edit)
    shift
    MODE="EDIT"
    while [[ "$#" -gt 0 ]]; do
      TARGETS+=("$1")
      shift
    done
    break
    ;;
  -b | backup)
    shift
    MODE="BACKUP"
    BACKUP_MODE="${1:-create}"
    shift
    case "$BACKUP_MODE" in
    create | remove | rollback)
      ;;
    *)
      _notify -e -a ct "Invalid BACKUP_MODE. Use -h / help for information"
      exit 1
      ;;
    esac
    ;;
  -l | list)
    shift
    MODE="LIST"
    ;;
  esac
done

case "$MODE" in
ADD)
  _dbAddEntry "$TITLE"
  ;;
DELETE)
  for id in "${TARGETS[@]}"; do
    _dbDeleteEntry "$id"
  done
  _dbReindex
  ;;
EDIT)
  for id in "${TARGETS[@]}"; do
    [[ -f "$ENTRY_DIR/entry_$id.md" ]] && kitty fish -c "n $ENTRY_DIR/entry_$id.md"
    _dbTouchEntry "$id"
  done
  ;;
BACKUP)
  case "$BACKUP_MODE" in
  create)
    _dbBackup
    ;;
  remove)
    #TODO: Make interactive backup remove
    ;;
  rollback)
    #TODO: Make interactive backup rollback
    ;;
  esac
  ;;
LIST)
  #TODO: Make entry data list dump
  ;;
esac
