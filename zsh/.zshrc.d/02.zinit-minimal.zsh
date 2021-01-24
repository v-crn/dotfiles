zinit wait lucid light-mode for \
    atinit"zicompinit; zicdreplay" \
    zdharma/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions

# history-search-multi-word with Ctrl+R
zinit light zdharma/history-search-multi-word

# auto-generate .gitignore from gitignore.io
# Usage: gi ruby >> .gitignore
function gi() { curl -sLw "\n" https://www.toptal.com/developers/gitignore/api/\$@; }
