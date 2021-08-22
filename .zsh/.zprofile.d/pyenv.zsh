if [ -e "/usr/local/bin/pyenv" ]; then
    # For pyenv installed from HomeBrew on macOS
    eval "$(pyenv init --path)"
elif [ -e "$HOME/.pyenv" ]; then
    # For pyenv installed from GitHub
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
fi
