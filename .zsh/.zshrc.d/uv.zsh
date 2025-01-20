if [ -e "$HOME/.local/bin/env" ]; then
    . "$HOME/.local/bin/env"
fi
if [ -e "$HOME/.local/bin/uv" ]; then
    eval "$(uv generate-shell-completion zsh)"
fi
