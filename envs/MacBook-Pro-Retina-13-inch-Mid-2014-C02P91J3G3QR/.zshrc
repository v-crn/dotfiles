#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

# 参考：https://qiita.com/agotoh/items/e6b22bcfe63162f70e0d
#---------------------------------------------------------
# zshのプラグイン管理ツールzplug
export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

# syntax
zplug "chrissicool/zsh-256color"
zplug "Tarrasch/zsh-colors"
zplug "zsh-users/zsh-syntax-highlighting"
zplug "ascii-soup/zsh-url-highlighter"

# 未インストール項目をインストールする
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# コマンドをリンクして、PATH に追加し、プラグインは読み込む
zplug load --verbose
#---------------------------------------------------------

# Default Language
# export LANG=ja_JP.UTF-8
# export LC_ALL=ja_JP.UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# .Net SDK path
PATH="${PATH}:/usr/local/share/dotnet"

# pipenv config
export PIPENV_VENV_IN_PROJECT=true

# pipenv command completion
eval "$(pipenv --completion)"
# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/Kosei/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/Kosei/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/Kosei/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/Kosei/google-cloud-sdk/completion.zsh.inc'; fi

export PATH="/usr/local/bin:$PATH"
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
