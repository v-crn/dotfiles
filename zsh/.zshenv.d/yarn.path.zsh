. ${ZDOTDIR:-$HOME}/functions/_command_exists.sh

_command_exists yarn || return

export PATH="$(yarn global bin):$PATH"
