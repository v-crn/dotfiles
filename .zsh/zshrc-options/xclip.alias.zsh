# For linux
_command_exists xclip || return

alias pbcopy='xclip -selection clipboard'
alias pbpaste='xclip -selection clipboard -o'
