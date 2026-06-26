#!/usr/bin/env bash

## EXTERNAL SCRIPTS

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

## HELPERS

# Create task file, defaults to template values if optional title/command not given
_createTaskFile() {
  [[ -z "$1" ]] && _notify -a nhc -u low -t 2000 "Failed to create task file" && exit 1

  local file="$1"
  local title="${2:-Title}"
  local command="${3:-Command}"

  jq -nc \
    --arg t "$title" \
    --arg c "$command" \
    '[{title:$t, command:$c, enabled:true}]' >"$file"

  return 0
}

_hasTaskTitle() {
  local file="$1"
  local title="$2"

  jq -e --arg t "$title" \
    '.[] | select(.title == $t and .enabled == true)' \
    "$file" >/dev/null
}

_hasTaskIndex() {
  local file="$1"
  local index="$2"

  jq -e --argjson i "$index" \
    '.[$i] | select(.enabled == true)' \
    "$file" >/dev/null
}

# Append new task to existing task file
_addTask() {
  [[ ! -f "$1" ]] && _notify -a nhc -u low -t 2000 "Cannot add task to invalid file: $1" && exit 1

  local file="$1"
  local title="$2"
  local command="$3"

  local tmp
  tmp=$(mktemp)

  jq \
    --arg t "$title" \
    --arg c "$command" \
    '. += [{"title": $t, "command": $c, "enabled": true}]' \
    "$file" >"$tmp" &&
    mv "$tmp" "$file"
  return 0
}

# Assumes _hasTaskIndex
_removeTaskIndex() {
  local file="$1"
  local index="$2"

  [[ ! -f "$file" ]] && _notify -a nhc -u low -t 2000 "Invalid task file: $file" && exit 1

  local len
  len=$(jq 'length' "$file") || return 1
  ((index < len)) || {
    _notify -a nhc -u low -t 2000 "Invalid index: $index"
    exit 1
  }

  local tmp
  tmp=$(mktemp) || {
    _notify -a nhc -u low -t 2000 "Failed to create tmp"
    exit 1
  }

  jq --argjson i "$index" '.[:$i] + .[$i+1:]' \
    "$file" >"$tmp" && mv "$tmp" "$file"
}

# Assumes _hasTaskTitle
_executeTask() {
  local file="$1"
  local title="$2"

  local command
  command=$(jq -r --arg t "$title" \
    '.[] | select(.title == $t) | .command' \
    "$file")

  bash -c "$command"
}

# Assumes _hasTaskIndex
_executeTaskIndex() {
  local file="$1"
  local index="$2"

  local command
  command=$(jq -r --argjson i "$index" \
    '.[$i].command' \
    "$file")

  bash -c "$command"
}

_printHelp() {
  cat <<EOF
    Task Runner
=====================
Options:
-t | --target-dir   | Sets <dir> (Defaults to working directory)
-a | --add          | Add task to file, prompts for title/command
-r | --run [-t] [-i]| Execute task command, will run first task, unless target specified *
-d | --delete <i>   | Delete a task by given index

Flags:
-np| --no-prompt    | Use template task when using --add, instead of prompting
-i | --init <dir>   | Creates template ds_task.json in <dir> [title] [command]

Alt Mode:
-w | --wofi         | Run in Wofi mode (* use --wofi help for more info)

Information:
--run can optionally be given a target title / index. Without one, is the same as doing:
  ./task_runner.sh -r index 0 ||  ./task_runner.sh -r -i 0


EOF
  return 0
}

## DECLARATIONS

TASK_FILE="ds_task.json"
TARGET_DIR="$PWD"
SKIP_PROMPT=0
WOFI_MODE=0

ADD_TITLE=""
ADD_COMMAND=""

## MAIN

[[ "$#" -eq 0 ]] && {
  _printHelp && exit 0
}

case "$1" in
-w | --wofi | wofi)
  WOFI_MODE=1
  shift
  ;;
esac

while [[ "$#" -gt 0 ]]; do
  if [[ "$WOFI_MODE" -eq 0 ]]; then
    # CLI MODE
    case "$1" in

    -w | --wofi | wofi)
      _notify -a nhc -u low -t 5000 "Invalid usage of Wofi mode, use --wofi help for more information"
      exit 1
      ;;

    -np | --no-prompt | noprompt)
      SKIP_PROMPT=1
      shift
      ;;

    -t | --target-dir | target)
      [[ ! -d "$2" ]] && _notify -a nhc -u low -t 2000 "Invalid Target Directory: $2" && exit 1
      TARGET_DIR="$2"
      shift 2
      ;;

    -i | --init | init)
      [[ -n "$2" ]] && TARGET_DIR="$2"
      [[ ! -d "$TARGET_DIR" ]] && _notify -a nhc -u low -t 2000 "Invalid Target Directory: $TARGET_DIR" && exit 1
      [[ -f "$TARGET_DIR/$TASK_FILE" ]] && _notify -a nhc -u low -t 2000 "Task file already exists at $TARGET_DIR" && exit 1
      _createTaskFile "$TARGET_DIR/$TASK_FILE" "$3" "$4"
      _notify -a nhc -u low -t 2000 "Created task file: $TARGET_DIR/$TASK_FILE"
      exit 0
      ;;

    -a | --add | add)
      [[ ! -f "$TARGET_DIR/$TASK_FILE" ]] && _notify -a nhc -u low -t 2000 "Task file does not exist in: $TARGET_DIR" && exit 1
      [[ "$SKIP_PROMPT" -eq 1 ]] && {
        ADD_TITLE="Title"
        ADD_COMMAND="Command"
      }

      [[ -z "$ADD_TITLE" ]] && {
        read -rp "[ADD TASK] Enter Title: " ADD_TITLE
        [[ -z "$ADD_TITLE" ]] && _notify -a nhc -u low -t 2000 "Aborted TaskRunner" && exit 0
      }

      [[ -z "$ADD_COMMAND" ]] && {
        read -rp "[ADD TASK] Enter Command: " ADD_COMMAND
        [[ -z "$ADD_COMMAND" ]] && _notify -a nhc -u low -t 2000 "Aborted TaskRunner" && exit 0
      }

      _addTask "$TARGET_DIR/$TASK_FILE" "$ADD_TITLE" "$ADD_COMMAND"
      _notify -a nhc -u low -t 2000 "Added Task: $ADD_TITLE" && exit 0
      ;;

    -d | --delete | delete | rm)
      RM_ID="$2"
      [[ -z "$RM_ID" ]] && RM_ID=0
      [[ "$2" =~ ^[0-9]+$ ]] || {
        _notify -a nhc -u low -t 2000 "Invalid index, must be numeric: $RM_ID"
        exit 1
      }
      if ! _hasTaskIndex "$TARGET_DIR/$TASK_FILE" "$RM_ID"; then
        _notify -a nhc -u low -t 2000 "Invalid index: $RM_ID" && exit 1
      else
        _removeTaskIndex "$TARGET_DIR/$TASK_FILE" "$RM_ID" && _notify -a nhc -u low -t 2000 "Removed task: $RM_ID" && exit 0
      fi
      ;;

    -r | --run | run)
      [[ ! -f "$TARGET_DIR/$TASK_FILE" ]] && _notify -a nhc -u low -t 2000 "Invalid task file: $TARGET_DIR/$TASK_FILE" && exit 1
      [[ -z "$2" ]] && {
        if _hasTaskIndex "$TARGET_DIR/$TASK_FILE" 0; then
          _executeTaskIndex "$TARGET_DIR/$TASK_FILE" 0
          exit 0
        else
          _notify -a nhc -u low -t 2000 "Task file is empty" && exit 1
        fi
      }

      case "$2" in

      -i | --index | index)
        [[ -z "$3" ]] && _notify -a nhc -u low -t 2000 "Expected index value" && exit 1
        [[ ! "$3" =~ ^[0-9]+$ ]] && _notify -a nhc -u low -t 2000 "Index must be numeric" && exit 1

        if _hasTaskIndex "$TARGET_DIR/$TASK_FILE" $3; then
          _executeTaskIndex "$TARGET_DIR/$TASK_FILE" $3
          exit 0
        else
          _notify -a nhc -u low -t 2000 "Invalid index for taskfile $3" && exit 1
        fi
        ;;

      -t | --title | title)
        [[ -z "$3" ]] && _notify -a nhc -u low -t 2000 "Expected title value" && exit 1

        if _hasTaskTitle "$TARGET_DIR/$TASK_FILE" $3; then
          _executeTask "$TARGET_DIR/$TASK_FILE" $3
          exit 0
        else
          _notify -a nhc -u low -t 2000 "Invalid title for taskfile $3" && exit 1
        fi
        ;;

      -*) _notify -a nhc -u low -t 2000 "Invalid option: $3" && exit 1 ;;
      *) _notify -a nhc -u low -t 2000 "Invalid value: $3" && exit 1 ;;
      esac
      ;;

    -*) _notify -a nhc -u low -t 2000 "Invalid Option Provided: $1" && exit 1 ;;
    *) _notify -a nhc -u low -t 2000 "Invalid Value Provided: $1" && exit 1 ;;
    esac
  else
    # TODO:
    # WOFI MODE
    _notify -a nhc -u low -t 2000 "Wofi mode not yet implemented" && exit 0
  fi
done
