if [ -e "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

if [ -e "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
