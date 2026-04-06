# dotfiles

chezmoi で管理する個人 dotfiles。WSL2 / macOS / Linux で動く zsh 環境と coding agents の共通設定を再現する。

## 動作環境

| 必須 | 任意 (なくても起動は壊れない) |
| --- | --- |
| zsh | eza, bat / batcat, fzf |
| chezmoi | mise, sheldon, starship |
| | Claude Code, Gemini CLI, Cursor (coding agents) |

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

```text
dotfiles/
├── home/                            # chezmoi ソースルート (.chezmoiroot)
│   ├── .chezmoiscripts/             # chezmoi スクリプト (~/には展開されない)
│   ├── dot_agents/                  # → ~/.agents/  (coding agents 共通ルール)
│   │   ├── AGENTS.md.tmpl           # 環境判定で動的生成
│   │   └── rules/                   # ルールファイル群
│   ├── dot_claude/                  # → ~/.claude/  (Claude Code 設定)
│   ├── dot_gemini/                  # → ~/.gemini/  (Gemini CLI 設定)
│   ├── dot_cursor/                  # → ~/.cursor/  (Cursor 設定)
│   ├── dot_zshenv.tmpl              # → ~/.zshenv
│   ├── dot_zprofile.tmpl            # → ~/.zprofile
│   ├── dot_zshrc.tmpl               # → ~/.zshrc
│   └── dot_config/
│       ├── chezmoi/                 # chezmoi 設定
│       ├── ccstatusline/            # → ~/.config/ccstatusline/ (Claude Code ステータスライン)
│       ├── sheldon/plugins.toml     # → ~/.config/sheldon/plugins.toml
│       └── zsh/                     # → ~/.config/zsh/*.zsh
├── tests/
│   └── test_zsh.bats                # bats-core によるシェルテスト
└── docs/                            # 詳細ドキュメント
```

## よく使うコマンド

```zsh
chezmoi diff                     # 差分確認
chezmoi apply                    # 適用
chezmoi edit ~/.zshrc            # マネージドファイルを編集して適用
chezmoi add ~/.<file>            # 新しいファイルを管理対象に追加
chezmoi managed                  # 管理対象ファイル一覧
chezmoi execute-template < home/dot_agents/AGENTS.md.tmpl  # テンプレート確認
bats tests/                      # テスト実行
```

## 詳細ドキュメント

- [セットアップ](docs/setup.md) — 新規マシンへの手順・トラブルシューティング
- [zsh 設定](docs/zsh.md) — 読み込み順・各ファイルの役割・設定追加方法
- ツール
  - [agents](docs/tools/agents.md) — Coding agents 共通ルール管理
  - [ccstatusline](docs/tools/ccstatusline.md) — Claude Code ステータスライン
  - [sheldon](docs/tools/sheldon.md) — Shell プラグインマネージャ
  - [starship](docs/tools/starship.md) — Shell プロンプト
  - [mise](docs/tools/mise.md) — ランタイムバージョン管理
  - [eza](docs/tools/eza.md) — ls 代替
  - [bat](docs/tools/bat.md) — cat 代替
  - [fzf](docs/tools/fzf.md) — ファジーファインダー
