if command -v eza &>/dev/null; then
    alias ls='eza --icons'
    alias ll='eza -lh --icons --git'
    alias la='eza -lha --icons --git'
    alias lt='eza --tree --icons'
fi
