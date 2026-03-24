# zsh 設定

## 起動ファイルの読み込み順

```
ログインシェル起動時:   zshenv → zprofile → zshrc
インタラクティブのみ:   zshenv → zshrc
スクリプト実行時:       zshenv のみ
```

| ファイル | 読み込まれるタイミング | 書くべき内容 |
|---------|----------------------|-------------|
| `~/.zshenv` | 常に (全シェル) | XDG_CONFIG_HOME, EDITOR, LANG 等の環境変数 |
| `~/.zprofile` | ログインシェル | PATH, Homebrew 等のログイン時のみ必要な設定 |
| `~/.zshrc` | インタラクティブシェル | プロンプト・エイリアス・プラグイン等 |

**zshenv の制約**: `echo` や `printf` は禁止 (SSH scp/rsync/sftp が壊れる)。`eval` も禁止。

## zshrc のモジュラー構成

`~/.zshrc` は薄いエントリポイントで、`~/.config/zsh/` 以下のファイルを順番にソースする。

```
history.zsh
keybindings.zsh
aliases.zsh
mise.zsh
sheldon.zsh      ← fpath にプラグインを追加するため compinit より前
completion.zsh   ← compinit 呼び出し + fzf-tab のロード
starship.zsh
```

### 読み込み順が重要な箇所

**sheldon.zsh → completion.zsh の順**
sheldon が `zsh-completions` を fpath に追加する。この処理が `compinit` より前に実行される必要がある。順序が逆だと `zsh-completions` の補完定義が有効にならない。

**fzf-tab は completion.zsh 内で compinit の後**
fzf-tab は zsh の補完システムに割り込む仕組みのため、`compinit` でシステムが初期化された後でなければロードできない。sheldon では `apply = []` にして自動ソースを無効化し、`completion.zsh` の末尾で条件付きで手動ロードしている。

## 各モジュールの役割

| ファイル | 役割 |
|---------|------|
| `history.zsh` | HISTFILE, HISTSIZE, 重複排除等のヒストリ設定 |
| `keybindings.zsh` | Emacs キーバインド、Up/Down のヒストリ検索 |
| `aliases.zsh` | eza/bat のエイリアス (ツールがなければスキップ) |
| `mise.zsh` | mise の activate (ツールがなければスキップ) |
| `sheldon.zsh` | sheldon でプラグインをロード + キーバインド上書き |
| `completion.zsh` | compinit + fzf-tab の条件付きロード |
| `starship.zsh` | starship プロンプトの初期化 |

## 設定を追加・変更する手順

```zsh
# 方法1: chezmoi 経由で編集 (apply まで一括)
chezmoi edit ~/.config/zsh/aliases.zsh

# 方法2: ソースファイルを直接編集
$EDITOR ~/dotfiles/home/dot_config/zsh/aliases.zsh
chezmoi diff
chezmoi apply

# 編集後にシェルへ反映
exec zsh
```

新しいモジュールファイルを追加する場合は `dot_zshrc.tmpl` の source リストにも追記する。
