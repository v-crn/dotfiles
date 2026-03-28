bindkey -e                        # Emacs key bindings

# Prefer history-substring-search if loaded by sheldon, else fall back to basic search
if zle -la 2>/dev/null | grep -q history-substring-search-up; then
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down
else
    bindkey '^[[A' history-search-backward
    bindkey '^[[B' history-search-forward
fi
