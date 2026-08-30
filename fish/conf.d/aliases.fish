# Other
alias cream="WEBKIT_DISABLE_DMABUF_RENDERER=1 exec /storage/Creamlinux_1.7.1_amd64.AppImage"

alias pacs="sudo pacman -Syu"
alias nvim="n"
alias sw="sw >/dev/null"
alias b="bash -lc"
alias nfrc="n ~/.config/fish/config.fish"
alias nbrc="n ~/.bashrc"
alias nas="n ~/.config/fish/conf.d/aliases.fish"
alias ssd="df -h | head -n 1; df -h | rg home; df -h | rg storage"
alias ff="fastfetch"
alias f="fetch --box -l arch --infinite"
alias csh="curl cheat.sh"
alias rqs="ps -o pid,rss,vsz,cmd -C qs"

alias otd="otimer -d"
alias ots="otimer -s"

alias wlc="wl-copy"
alias wlp="wl-paste"

alias ou="omusic -u"
alias om="omake"

#Music stuff because am lazy ja
alias fm="$HOME/.config/bash/scripts/fmp3.sh"
alias sm="$HOME/.config/bash/scripts/syncPhoneMusic.sh -v"
alias rmmp3="$HOME/.config/bash/scripts/fixYoutubeMusic_Duplicates.sh"

# Builtin Shorthands
alias Q="exit"
alias q="exit"
alias a="alias"
alias c="clear"
alias cls="clear && ls"
alias cla="clear && la"
alias ..="cd .."
alias cdt="cd -"
alias sof="source ~/.config/fish/config.fish"
alias sob="source ~/.bashrc"
alias hl="rg --passthru"
alias ls='ls -F --color=auto --show-control-chars'
alias bat="bat --color=always"

# Git / GH
alias gs="git status"
alias gl="git log"
alias gb="git branch"
alias gc="git checkout"
alias gr="git remote -v"
alias ghl="gh repo list"

alias lg="lazygit"
