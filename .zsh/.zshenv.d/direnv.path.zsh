export EDITOR=vim

_command_exists direnv || return
eval "$(direnv hook zsh)"
