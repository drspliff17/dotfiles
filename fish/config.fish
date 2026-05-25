source /usr/share/cachyos-fish-config/cachyos-config.fish

set -Ux QML2_IMPORT_PATH "/usr/lib/qt6/qml:$HOME/.config/quickshell/modules"
set -gx FZF_DEFAULT_OPTS "
--layout=reverse
--border
--inline-info
"
# --color=bg:#1e1e2e,bg+:#313244,fg:#cdd6f4,fg+:#f5e0dc
# --color=hl:#f38ba8,hl+:#f38ba8
# --color=info:#cba6f7,prompt:#89b4fa,pointer:#f5e0dc
# --color=marker:#a6e3a1,spinner:#f5e0dc,header:#fab387

cat ~/.cache/wal/sequences
function fish_greeting
end

set -x EDITOR "fish -c n"

zoxide init fish | source
