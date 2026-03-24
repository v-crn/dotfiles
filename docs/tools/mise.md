# mise

ランタイムのバージョン管理ツール。Node.js, Python, Go, Rust 等を管理できる。
asdf の後継にあたる。

## インストール

```zsh
# macOS
brew install mise

# Linux / WSL2
curl https://mise.run | sh
```

## dotfiles での管理

`mise.zsh` が `eval "$(mise activate zsh)"` を実行する。
mise がインストールされていなければ何もしない。

## よく使うコマンド

```zsh
mise use node@lts          # カレントディレクトリに Node.js LTS を設定
mise use --global node@lts # グローバルに設定
mise install               # .mise.toml に書かれたバージョンをインストール
mise list                  # インストール済みバージョン一覧
mise current               # 現在アクティブなバージョン一覧
```

## Tips

プロジェクトルートに `.mise.toml` を置くとディレクトリ移動時に自動で切り替わる。

```toml
# .mise.toml
[tools]
node = "22"
python = "3.12"
```
