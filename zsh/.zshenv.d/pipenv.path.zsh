. ${ZDOTDIR:-$HOME}/functions/_command_exists.sh

_command_exists pipenv || return
export PIPENV_VENV_IN_PROJECT=true
