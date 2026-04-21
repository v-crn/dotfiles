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

`mise.zsh` は `eval "$(mise activate zsh --shims)"` を実行する。
mise がインストールされていなければ何もしない。

`--shims` を使う理由は、フル activate の `hook-env` 常駐を避けるため。
一部ツールは shell 起動時に追加の integration 初期化を行い、副作用のある一時ファイルや
一時 PATH を作ることがある。dotfiles では zsh 起動を安定させることを優先し、shims ベース
でコマンド解決だけを有効化する。

副作用として、通常の `mise activate zsh` が提供する prompt/chpwd hook ベースの動的更新は
使わない。つまり、shell のたびに `hook-env` を実行して PATH や環境を細かく再計算する挙動は
抑止される。dotfiles ではこのトレードオフを受け入れ、必要なツール解決は shims に任せる。

## Troubleshooting

### zsh 起動でカレントディレクトリに `.codex` が作られる

症状:

- `zsh` を開くと、そのときのカレントディレクトリに空の `.codex` ファイルができることがある

原因:

- `mise activate zsh` の `hook-env` 常駐経由で Codex の shell integration が評価され、
  `~/.codex/tmp/arg0/...` のような一時 PATH 注入や `.codex` 系の副作用が起動時に混ざることがあった

対策:

- dotfiles では `mise activate zsh --shims` に切り替え、`hook-env` 常駐を無効化した
- これにより zsh 起動時の Codex integration 評価を避け、カレントディレクトリへの `.codex`
  ファイル生成を防ぐ

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
