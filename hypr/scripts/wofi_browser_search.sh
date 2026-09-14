#!/usr/bin/env bash

source "$HOME/.config/bash/lib/wofi_construct.sh"

WOFI_PROMPT="Enter search query ..."
WOFI_WIDTH="30%"
WOFI_HEIGHT="10%"
WOFI_CONFIG="$WOFI_C_CENTER"

w_args=()
_construct w_args

search="$(wofi -d "${w_args[@]}")"
[[ -z "$search" ]] && exit 0
search=${search// /+}
firefox --new-window "https://www.google.com/search?client=firefox-b-d&q=$search"
