#!/usr/bin/env bash

# Kitty Sockets (specifically needed for tab bar pywal update)
for paw in /tmp/kitty-*; do
  [[ -S "$paw" ]] || continue

  kitty @ --to "unix:$paw" set-colors \
    --all \
    --configured \
    "$HOME/.cache/wal/colors-kitty.conf"
done

# Neovim
for sock in /tmp/nvim-*; do
  if [[ -S "$sock" ]]; then
    nvim --server "$sock" \
      --remote-expr "execute ('colorscheme pywal')"
  fi
done

# Firefox
pywalfox update

# Discord
pywal-discord -t mywal

# BTOP
pgrep btop && kill -USR2 $(pgrep btop)

# My programs
pgrep omusic && kill -USR1 $(pgrep omusic)
pgrep dcalc && kill -USR1 $(pgrep dcalc)
pgrep ds_pet && kill -USR1 $(pgrep ds_pet)
pgrep oofi && kill -USR1 $(pgrep oofi)
pgrep colourSort && kill -USR1 $(pgrep colourSort)
pgrep ds_menu && kill -USR1 $(pgrep ds_menu)
pgrep otv_gui && kill -USR1 $(pgrep otv_gui)
pgrep oshell && kill -USR1 $(pgrep oshell)

# Cmus
exec ~/.config/bash/scripts/cmus_update_colours.sh
