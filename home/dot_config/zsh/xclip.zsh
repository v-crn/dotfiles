# For linux
command -v xclip &>/dev/null || return

alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
