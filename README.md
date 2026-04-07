# dotfiles

自分用 dotfiles リポジトリ。

- **Target environment:** WSL2 / Linux / macOS
- **Dotfile Manager:** chezmoi
- **Shell:** zsh with sheldon (plugins), starship (prompt)

## Requirements

### Required

- [chezmoi](https://github.com/twpayne/chezmoi)

### Preferred

- [make](https://github.com/mirror/make)
- [shellcheck](https://github.com/koalaman/shellcheck)
- [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2)
- [lefthook](https://github.com/evilmartians/lefthook)

## Quickstart

```zsh
git clone https://github.com/v-crn/dotfiles
cd dotfiles
make diff    # 変更内容を確認
make apply   # 適用
```

sheldon を使う場合はプラグインをダウンロード:

```zsh
sheldon lock
```

## Structure

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

## Common Commands

### make commands

@Makefile 参照

### chezmoi commands

[docs/tools/chezmoi.md](docs/tools/chezmoi.md) 参照

## 詳細ドキュメント

- [セットアップ](docs/setup.md) — 新規マシンへの手順・トラブルシューティング
- [zsh 設定](docs/zsh.md) — 読み込み順・各ファイルの役割・設定追加方法
- ツール
  - [chezmoi](docs/tools/chezmoi.md) — dotfiles 管理
  - [agents](docs/tools/agents.md) — Coding agents 共通ルール管理
  - [ccstatusline](docs/tools/ccstatusline.md) — Claude Code ステータスライン
  - [sheldon](docs/tools/sheldon.md) — Shell プラグインマネージャ
  - [starship](docs/tools/starship.md) — Shell プロンプト
  - [mise](docs/tools/mise.md) — ランタイムバージョン管理
  - [eza](docs/tools/eza.md) — ls 代替
  - [bat](docs/tools/bat.md) — cat 代替
  - [fzf](docs/tools/fzf.md) — ファジーファインダー
