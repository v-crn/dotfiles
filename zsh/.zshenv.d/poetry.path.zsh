. ${ZDOTDIR:-$HOME}/functions/_command_exists.sh

_command_exists poetry || return
export PATH="$HOME/.poetry/bin:$PATH"
