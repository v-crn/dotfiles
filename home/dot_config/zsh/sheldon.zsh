if command -v sheldon &>/dev/null; then
    eval "$(sheldon source)"

    # Bind Up/Down to history-substring-search if the plugin was loaded
    if zle -la 2>/dev/null | grep -q history-substring-search-up; then
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
    fi
fi
