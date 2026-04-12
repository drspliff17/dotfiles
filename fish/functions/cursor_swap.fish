#!/usr/bin/env fish

function cursor_swap
    set -l themePath "$HOME/.config/cursor/cursorThemes"
    if not test -e $themePath
        echo "[Error] Cursor Themes File not found"
        return 1
    end
    set -l selected (fzf < $themePath)
    if test -z "$selected"
        echo "[Info] Theme was not changed: currently"
        return 1
    end
    hyprctl setcursor $selected $HYPRCURSOR_SIZE
    return 0
end
