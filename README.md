# dotfiles

chezmoi で管理する個人 dotfiles。WSL2 / macOS / Linux で動く zsh 環境を再現する。

## 動作環境

| 必須 | 任意 (なくても起動は壊れない) |
|------|-------------------------------|
| zsh | eza, bat / batcat, fzf |
| chezmoi | mise, sheldon, starship |

## クイックスタート

```zsh
git clone <repo-url> ~/dotfiles
chezmoi init --source ~/dotfiles
chezmoi diff          # 変更内容を確認
chezmoi apply         # 適用
```

sheldon を使う場合はプラグインをダウンロード:

```zsh
sheldon lock
```

## リポジトリ構成

```
dotfiles/
├── home/                        # chezmoi ソースルート (.chezmoiroot)
│   ├── dot_zshenv.tmpl          # → ~/.zshenv
│   ├── dot_zprofile.tmpl        # → ~/.zprofile
│   ├── dot_zshrc.tmpl           # → ~/.zshrc
│   ├── dot_config/
│   │   ├── sheldon/plugins.toml # → ~/.config/sheldon/plugins.toml
│   │   └── zsh/                 # → ~/.config/zsh/*.zsh
│   └── run_once_*.sh            # chezmoi が初回のみ実行するスクリプト
├── tests/
│   └── test_zsh.bats            # bats-core によるシェルテスト
└── docs/                        # 詳細ドキュメント
```

## よく使うコマンド

```zsh
chezmoi diff                     # 差分確認
chezmoi apply                    # 適用
chezmoi edit ~/.zshrc            # マネージドファイルを編集して適用
chezmoi add ~/.<file>            # 新しいファイルを管理対象に追加
chezmoi managed                  # 管理対象ファイル一覧
bats tests/                      # テスト実行
```

## 詳細ドキュメント

- [セットアップ](docs/setup.md) — 新規マシンへの手順・トラブルシューティング
- [zsh 設定](docs/zsh.md) — 読み込み順・各ファイルの役割・設定追加方法
- ツール
  - [sheldon](docs/tools/sheldon.md) — プラグインマネージャ
  - [starship](docs/tools/starship.md) — プロンプト
  - [mise](docs/tools/mise.md) — ランタイムバージョン管理
  - [eza](docs/tools/eza.md) — ls 代替
  - [bat](docs/tools/bat.md) — cat 代替
  - [fzf](docs/tools/fzf.md) — ファジーファインダー
