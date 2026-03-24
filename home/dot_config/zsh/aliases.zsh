if command -v eza &>/dev/null; then
    alias ls='eza --icons'
    alias ll='eza -lh --icons --git'
    alias la='eza -lha --icons --git'
    alias lt='eza --tree --icons'
fi
if command -v bat &>/dev/null; then
    alias cat='bat --paging=never'
elif command -v batcat &>/dev/null; then
    alias bat='batcat'
    alias cat='batcat --paging=never'
fi
