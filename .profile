if [ "$(uname -s)" = 'Darwin' ]; then
    # macOS
    if [ -e "/usr/local/bin/pyenv" ]; then
        eval "$(pyenv init --path)"
    elif [ -e "$HOME/.pyenv" ]; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
    else
        echo 'pyenv is not found at "/usr/local/bin/pyenv" or at "$HOME/.pyenv"'
    fi
else
    if [ -e "$HOME/.pyenv" ]; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init --path)"
        eval "$(pyenv init --path)"
    else
        echo 'pyenv is not found at "$HOME/.pyenv"'
    fi
fi
