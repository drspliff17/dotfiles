#!/usr/bin/env bash

[[ -n "${BASH_VERSION:-}" ]] || return 0

alias bm="bookmark"

# Bookmark System
bookmark() {

  ## Defs

  local directory_path="$HOME/DS_Bookmarks"
  local file_path="$directory_path/ds_bookmarks.json"

  local mode=""
  local doSave="false"

  local bookmark_name bookmark_value bookmark_exists
  local unsaved_bookmark_count

  ## Local Helper Functions

  _createBookmarkJSON() {
    touch "$file_path"
    echo '{"bookmarks":{}}' >"$file_path"
    return 0
  }

  _init() {
    read -rp "[Initialisation] Bookmark Data not found, would you like to create it now? (Enter either y/Y) [Path: $directory_path] [File: ds_bookmarks.json]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "[Initialisation] Aborted. Return anytime using 'bookmark' OR 'bm'"
      return 1
    fi
    mkdir "$directory_path"
    _createBookmarkJSON
    echo "[Initialisation] Required bookmark directory and file created. For information, use 'bm help'"
    return 0
  }

  _check_bookmark_exists() {
    local name="$1"
    local exists=$(jq --arg name "$name" '.bookmarks | has($name)' "$file_path")
    if [[ "$exists" != "true" ]]; then
      return 1
    fi
    return 0
  }

  _check_standard_error() {
    if [[ -z "$bookmark_name" ]]; then
      echo "[Error] Expected Bookmark Name, see 'bm help' for more information" >&2
      return 1
    fi

    if ! _check_bookmark_exists "$bookmark_name"; then
      echo "[Error] Bookmark '$bookmark_name' does not exist" >&2
      return 1
    fi

    return 0
  }

  _toggle_bookmark_save() {
    local bm_name="$1"
    local bm_bool="$2"
    if [[ "$bm_bool" = "true" ]]; then
      jq --arg name "$bm_name" '.bookmarks[$name].saved = true' \
        "$file_path" >"$file_path.tmp" && mv "$file_path.tmp" "$file_path"
      return 0
    else
      jq --arg name "$bm_name" '.bookmarks[$name].saved = false' \
        "$file_path" >"$file_path.tmp" && mv "$file_path.tmp" "$file_path"
      return 0
    fi
  }

  _list_bookmarks() {
    echo "Bookmarks:"
    jq -r '
    .bookmarks
    | to_entries
    | sort_by((.value.saved | not), .key)   # saved=true first, then by key
    | .[]
    | "\(.key) | \(.value.value)\(if .value.saved then " [SAVED]" else "" end)"
    ' "$file_path"
  }

  _help() {
    cat <<'HELP'
DS Bookmark System Information
---------------------------
Subcommands:                                     [Example]
  help   [-h]    | Prints System Information    : "bm help"

  add    [-a]    | Adds bookmark                : "bm add [bm name] [bm value]"
  remove [-r]    | Removes bookmark             : "bm remove [bm name]"

  save   [-s]    | Sets bookmark to saved       : "bm save [bm name]"
  unsave [-u]    | Unsets bookmark from saved   : "bm unsave [bm name]"

  clear  [-C]    | Remove all unsaved bookmarks : "bm clear"

  name   [-n]    | Edit bookmark name           : "bm name [current name] [new name]"

  get    [-g]    | Echos value of bookmark      : "bm get [bm name]"

  execute[-e]    | Evaluates value of bookmark  : "bm execute [bm name]"
--------------------------
Info:
- System can be called with either "bookmark" or "bm". Subcommands accept any listed alternatives

- To list all bookmarks, simply call system without any subcommands

- Supports Tab-Completion for Subcommands, and Bookmark names

- When storing values with spaces, ensure to use quotation ""

- Add && Save Subcommands can be combined in single call: "bm a s [name] [value]" -> This will add the bookmark, saved automatically.
HELP
    return 0
  }

  ## Main

  # Argument Parsing
  while [[ "$#" -gt 0 ]]; do
    case "$1" in

    help | -h)
      _help
      return 0
      ;;

    add | -a)
      if [[ -z "$mode" ]]; then
        mode="add"
      fi
      shift
      ;;

    remove | -r)
      if [[ -z "$mode" ]]; then
        mode="remove"
      fi
      shift
      ;;

    save | -s)
      if [[ -z "$mode" ]]; then
        mode="save"
      else
        doSave="true"
      fi
      shift
      ;;

    unsave | -u)
      if [[ -z "$mode" ]]; then
        mode="unsave"
      fi
      shift
      ;;

    clear | -C)
      if [[ -z "$mode" ]]; then
        mode="clear"
      fi
      shift
      ;;

    name | -n)
      if [[ -z "$mode" ]]; then
        mode="name"
      fi
      shift
      ;;

    get | -g)
      if [[ -z "$mode" ]]; then
        mode="get"
      fi
      shift
      ;;

    execute | -e)
      if [[ -z "$mode" ]]; then
        mode="execute"
      fi
      shift
      ;;

    *)
      if [[ -z "$bookmark_name" ]]; then
        bookmark_name="$1"
      elif [[ -z "$bookmark_value" ]]; then
        bookmark_value="$1"
      else
        echo "[Error] Unexpected argument: $1" >&2
        return 1
      fi
      shift
      ;;
    esac
  done

  # Guard Clauses
  if [[ ! -d "$directory_path" ]]; then
    _init
    return 0
  fi

  if [[ ! -f "$file_path" ]]; then
    echo "[Error] Expected file [$file_path] not found. Creating new ds_bookmarks.json..." >&2
    _createBookmarkJSON
    echo "[Initialisation] File Created. Displaying Information:"
    echo ""
    _help
    return 1
  fi

  # Operation
  if [[ -z "$mode" ]]; then
    _list_bookmarks
    return 0
  fi

  case "$mode" in
  add)
    if [[ -z "$bookmark_value" ]]; then
      echo "[Error] Bookmark expected value, to add. Use 'bm help' for more information" >&2
      return 1
    fi

    if _check_bookmark_exists "$bookmark_name"; then
      read -rp "[Warning] Bookmark '$bookmark_name' already exists, would you like to overwrite it? (Y/y): " confirm
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "[Bookmark Add Aborted]"
        return 1
      fi
    fi

    jq \
      --arg name "$bookmark_name" \
      --arg value "$bookmark_value" \
      --argjson saved "$doSave" \
      '.bookmarks[$name] = {value:$value, saved:$saved}' \
      "$file_path" >"$file_path.tmp" && mv "$file_path.tmp" "$file_path"

    echo "[Bookmark Added] '$bookmark_name' -> '$bookmark_value'"
    return 0
    ;;

  remove)
    if ! _check_standard_error; then
      return 1
    fi

    jq \
      --arg name "$bookmark_name" \
      'del(.bookmarks[$name])' \
      "$file_path" >"$file_path.tmp" && mv "$file_path.tmp" "$file_path"

    echo "[Bookmark Removed] '$bookmark_name'"
    return 0
    ;;

  save)
    if ! _check_standard_error; then
      return 1
    fi

    _toggle_bookmark_save "$bookmark_name" "true"

    echo "[Bookmark Saved] '$bookmark_name'"
    return 0
    ;;

  unsave)
    if ! _check_standard_error; then
      return 1
    fi

    _toggle_bookmark_save "$bookmark_name" "false"

    echo "[Bookmark Unsaved] '$bookmark_name'"
    return 0
    ;;

  clear)
    unsaved_bookmark_count=$(jq '[.bookmarks[] | select(.saved == false)] | length' "$file_path")
    if [[ "$unsaved_bookmark_count" -eq 0 ]]; then
      echo "[Error] No unsaved bookmarks to remove"
      return 1
    fi

    read -rp "[Warning] This will remove ALL unsaved bookmarks, are you sure you would like to continue? (Y/y): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
      echo "[Bookmark Clear Aborted]"
      return 1
    fi

    jq 'delpaths([.bookmarks | to_entries[] | select(.value.saved == false) | ["bookmarks", .key]])' \
      "$file_path" >"$file_path.tmp" && mv "$file_path.tmp" "$file_path"

    echo "[Unsaved Bookmarks Cleared] Removed $unsaved_bookmark_count bookmark(s)"
    return 0
    ;;

  name)
    if ! _check_standard_error; then
      return 1
    fi

    if [[ -z "$bookmark_value" ]]; then
      echo "[Error] Expected new Bookmark name" >&2
      return 1
    fi

    if _check_bookmark_exists "$bookmark_value"; then
      read -rp "[Warning] Bookmark '$bookmark_value' already exists, would you like to overwrite it? (Y/y): " confirm
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "[Bookmark Rename Aborted]"
        return 1
      fi
    fi

    jq --arg old "$bookmark_name" --arg new "$bookmark_value" \
      '.bookmarks[$new] = .bookmarks[$old] | del(.bookmarks[$old])' \
      "$file_path" >"$file_path.tmp" && mv "$file_path.tmp" "$file_path"

    echo "[Bookmark Renamed] '$bookmark_name' -> '$bookmark_value'"
    return 0
    ;;

  get)
    if ! _check_standard_error; then
      return 1
    fi

    jq -r --arg name "$bookmark_name" '.bookmarks[$name].value' "$file_path"
    return 0
    ;;

  execute)
    if ! _check_standard_error; then
      return 1
    fi

    eval "$(bookmark get "$bookmark_name")"
    return 0
    ;;
  esac

}

_bookmark_complete() {

  local directory_path="$HOME/DS_Bookmarks"
  local file_path="$directory_path/ds_bookmarks.json"

  local cur prev
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local commands="add remove save unsave clear name get help execute"

  if [[ $COMP_CWORD -eq 1 ]]; then
    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    return
  fi

  [[ -f "$file_path" ]] || return

  local keys
  keys=$(jq -r '.bookmarks | keys[]' "$file_path" 2>/dev/null)

  case "${COMP_WORDS[1]}" in

  remove | save | unsave | get | name | execute)
    if [[ $COMP_CWORD -eq 2 ]]; then
      COMPREPLY=($(compgen -W "$keys" -- "$cur"))
    fi
    ;;
  esac
}
complete -F _bookmark_complete bm
complete -F _bookmark_complete bookmark
complete -F _bookmark_complete cdb
