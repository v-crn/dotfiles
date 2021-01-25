. ${ZDOTDIR:-$HOME}/functions/_command_exists.sh

_command_exists goenv || return

# go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$PATH

# goenv
export GOENV_ROOT=$HOME/.goenv
export PATH=$GOENV_ROOT/bin:$PATH
export PATH=$HOME/.goenv/bin:$PATH
eval "$(goenv init -)"
