if [ -e "$HOME/go" ]; then
    export GOPATH=$HOME/go
    export PATH=$GOPATH/bin:$PATH
fi
command -v goenv &>/dev/null || return
eval "$(goenv init -)"
