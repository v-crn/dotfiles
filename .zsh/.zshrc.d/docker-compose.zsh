## docker/compose プラグインは macOS では問題ないが、Debian 9 では /usr/local/bin より先にパスが記述されることで docker-compose が無反応になる不具合が起きる
# zinit ice from"gh-r" as"program" mv"docker* -> docker-compose" bpick"*linux*"
# zinit load docker/compose

alias dc='docker-compose'
alias dcbuild='docker-compose build'
alias dcup='docker-compose up'
