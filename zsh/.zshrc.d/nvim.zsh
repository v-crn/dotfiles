. ${ZDOTDIR:-$HOME}/functions/_command_exists.sh

_command_exists nvim || return

alias vim='nvim'
alias vimcf='vim ~/.config/nvim'
