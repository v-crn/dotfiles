export PATH="$HOME/.pyenv/bin:$PATH"

_command_exists pyenv || return
eval "$(pyenv init -)"

_command_exists pyenv virtualenv-init || return
eval "$(pyenv virtualenv-init -)"
