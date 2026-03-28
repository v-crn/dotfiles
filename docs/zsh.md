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

`~/.zshrc` は薄いエントリポイントで、`~/.config/zsh/*.zsh` を glob でまとめてロードする。ファイルはアルファベット順に読み込まれ、順序制約があるファイルには数字プレフィックスを付けて先頭に固定する。

```
50_sheldon.zsh   ← fpath にプラグインを追加するため compinit より前
60_completion.zsh ← compinit 呼び出し + fzf-tab のロード
aliases.zsh
dart.zsh
...（ツール別ファイルはアルファベット順）
keybindings.zsh  ← sheldon のロード後に実行されるためプラグインの有無を確認可能
...
starship.zsh
xclip.zsh
```

### 読み込み順が重要な箇所

**50_sheldon.zsh → 60_completion.zsh の順**
sheldon が `zsh-completions` を fpath に追加する。この処理が `compinit` より前に実行される必要がある。数字プレフィックスでアルファベット順より前に固定している。

**keybindings.zsh は sheldon の後**
keybindings.zsh はロード時に `history-substring-search` ウィジェットの存在を確認し、利用可能なら Up/Down にバインドする。sheldon（50\_）がアルファベット（k）より前にロードされるため、確認が成立する。

**fzf-tab は 60_completion.zsh 内で compinit の後**
fzf-tab は zsh の補完システムに割り込む仕組みのため、`compinit` でシステムが初期化された後でなければロードできない。sheldon では `apply = []` にして自動ソースを無効化し、`60_completion.zsh` の末尾で条件付きで手動ロードしている。

## 各モジュールの役割

| ファイル | 役割 |
| --- | --- |
| `50_sheldon.zsh` | sheldon でプラグインをロード |
| `60_completion.zsh` | compinit + fzf-tab の条件付きロード |
| `aliases.zsh` | eza/bat のエイリアス (ツールがなければスキップ) |
| `dart.zsh` | Dart pub-cache の PATH 追加 |
| `docker-compose.zsh` | docker compose のエイリアス |
| `dotnet.zsh` | .NET SDK の PATH 追加 |
| `flutter.zsh` | Flutter / FVM の PATH 追加 |
| `git.zsh` | git エイリアス |
| `golang.zsh` | GOPATH の設定、goenv の初期化 |
| `google-cloud-sdk.zsh` | gcloud 補完の読み込み |
| `history.zsh` | HISTFILE, HISTSIZE, 重複排除等のヒストリ設定 |
| `homebrew.zsh` | Homebrew の PATH 追加 (macOS) |
| `keybindings.zsh` | Emacs キーバインド、Up/Down のヒストリ検索 |
| `mise.zsh` | mise の activate (ツールがなければスキップ) |
| `nvcc.zsh` | CUDA / cuDNN の PATH 追加 |
| `nvidia-smi.zsh` | nvidia-smi 用 WSL PATH 追加 |
| `nvim.zsh` | neovim のエイリアス |
| `rust.zsh` | Cargo の PATH 追加 |
| `starship.zsh` | starship プロンプトの初期化 |
| `xclip.zsh` | pbcopy/pbpaste エイリアス (Linux) |

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

新しいモジュールファイルを `~/.config/zsh/` に追加するだけで自動的にロードされる。順序制約がある場合は数字プレフィックスを付ける。
