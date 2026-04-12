#!/usr/bin/env bash

[[ -n "${BASH_VERSION:-}" ]] || return 0

# CD But with support for Bookmark System
cdb() {
  source ~/.config/bash/functions/bookmark.sh
  local bm_name="$1"
  [ -z "$bm_name" ] && {
    echo "Usage: cdb <bookmark>" >&2
    return 1
  }

  local target
  target="$(bookmark get "$bm_name")"
  if [ -z "$target" ]; then
    # error is passed from bookmark system
    return 1
  fi

  if [ ! -d "$target" ]; then
    echo "Target '$target' is not a valid directory" >&2
    return 1
  fi

  echo "$target"
  return 0
}

# Tab completion for cdb
_cdb_completion() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local file_path="$HOME/DS_Bookmarks/ds_bookmarks.json"

  [[ $COMP_CWORD -ne 1 ]] && return
  [[ -f "$file_path" ]] || return

  local keys
  keys=$(jq -r '.bookmarks | keys[]' "$file_path" 2>/dev/null | tr -d '\r')

  COMPREPLY=($(compgen -W "$keys" -- "$cur"))
}

complete -o default -F _cdb_completion cdb
