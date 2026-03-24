autoload -Uz compinit && compinit

# fzf-tab replaces zsh's default completion UI with fzf; must be loaded after compinit.
# Cloned via sheldon (apply = []) but sourced here to enforce load order.
if command -v fzf &>/dev/null; then
    _fzf_tab="${SHELDON_DATA_DIR:-$HOME/.local/share/sheldon}/repos/github.com/Aloxaf/fzf-tab/fzf-tab.zsh"
    [[ -f "$_fzf_tab" ]] && source "$_fzf_tab"
    unset _fzf_tab
fi
