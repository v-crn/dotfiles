# go
if [ -e "$HOME/go" ]; then
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH
fi

# goenv
if [ -e "$HOME/.goenv" ]; then
    export GOENV_ROOT=$HOME/.goenv
    export PATH=$GOENV_ROOT/bin:$PATH
    export PATH=$HOME/.goenv/bin:$PATH
fi

_command_exists goenv || return

eval "$(goenv init -)"
