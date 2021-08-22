_command_exists pyenv || return

if [ -e "$(pyenv root)/plugins/pyenv-virtualenv" ]; then
    # To enable auto-activation of virtualenvs.
    eval "$(pyenv virtualenv-init -)"
fi
