# zplug: zshのプラグイン管理ツール
export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

# 非同期処理できるようになる
zplug "mafredri/zsh-async"
# テーマ
zplug "sindresorhus/pure"
# 構文のハイライト
zplug "zsh-users/zsh-syntax-highlighting"
# URLのハイライト
zplug "ascii-soup/zsh-url-highlighter"
# コマンド入力途中で上下キー押したときの過去履歴がいい感じに出る
zplug "zsh-users/zsh-history-substring-search"
# 過去に入力したコマンドの履歴が灰色のサジェストで出る
zplug "zsh-users/zsh-autosuggestions"
# 補完強化
zplug "zsh-users/zsh-completions"
# 256色表示
zplug "chrissicool/zsh-256color"
# Imagine a shell where red ERROR just works
zplug "Tarrasch/zsh-colors"
# コマンドライン上の文字リテラルの絵文字を emoji 化する
zplug "mrowa44/emojify", as:command
# dotfiles 管理フレームワーク
zplug "ssh0/dot", use:"*.sh"
export DOT_REPO="https://github.com/v-crn/dotfiles.git"
export DOT_DIR="$HOME/dotfiles"

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
  printf "Install? [y/N]: "
  if read -q; then
    echo
    zplug install
  fi
fi

# Then, source plugins and add commands to $PATH
zplug load

# 参考
# [macのterminal設定 (iterm2 & zsh、テーマはIceberg) - Qiita](https://qiita.com/agotoh/items/e6b22bcfe63162f70e0d)
# [初心者でもできる！zsh＋zplugの導入 - Qiita](https://qiita.com/tatsugon14/items/7a7390f8d45b276fcbb1)
