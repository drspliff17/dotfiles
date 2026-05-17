# Other
alias nvim="n"
alias sw="swap_wallpaper >/dev/null"
alias b="bash -lc"
alias nfrc="n ~/.config/fish/config.fish"
alias nbrc="n ~/.bashrc"
alias nas="n ~/.config/fish/conf.d/aliases.fish"
alias ssd="df -h | head -n 1; df -h | rg home; df -h | rg storage"
alias ff="fastfetch"

#Music stuff because am lazy ja
alias fm="$HOME/.config/bash/scripts/fmp3.sh"
alias sm="$HOME/.config/bash/scripts/syncPhoneMusic.sh -v"
alias rmmp3="$HOME/.config/bash/scripts/fixYoutubeMusic_Duplicates.sh"
alias gm="getmusic"

# Builtin Shorthands
alias Q="exit"
alias q="exit"
alias a="alias"
alias c="clear"
alias cls="clear && ls"
alias ..="cd .."
alias cdt="cd -"
alias sof="source ~/.config/fish/config.fish"
alias sob="source ~/.bashrc"
alias hl="rg --passthru"
alias ls='ls -F --color=auto --show-control-chars'
alias bat="bat --color=always"

# Git / GH
alias gs="git status"
alias gb="git branch"
alias gc="git checkout"
alias gr="git remote -v"
alias ghl="gh repo list"

alias lg="lazygit"

alias getmusic="$HOME/.config/bash/scripts/automatic_ytdlp.sh"
