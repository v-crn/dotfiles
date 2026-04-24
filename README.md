# dotfiles

自分用 dotfiles リポジトリ。

- **Target environment:** WSL2 / Linux / macOS
- **Dotfile Manager:** chezmoi
- **Shell:** zsh with sheldon (plugins), starship (prompt)

## Requirements

### Required

- [chezmoi](https://github.com/twpayne/chezmoi)
- [jqlang/jq: Command-line JSON processor](https://github.com/jqlang/jq)

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
│   ├── .chezmoitemplates/           # 共有 chezmoi named templates
│   │   └── AGENTS.md.tmpl           # coding agents 共通ルール本体
│   ├── dot_agents/                  # → ~/.agents/  (coding agents 共通ルール・スキル)
│   │   ├── AGENTS.md.tmpl           # 共有テンプレートのエントリーポイント
│   │   └── skills/                  # 共有スキル（chezmoi apply でリンクを自動作成）
│   ├── dot_claude/                  # → ~/.claude/  (Claude Code 設定)
│   │   ├── CLAUDE.md.tmpl           # 共有テンプレートのエントリーポイント
│   │   ├── hooks/                   # Claude Code hooks（セキュリティ・通知）
│   │   └── run_apply-claude-settings.sh  # settings.json 生成スクリプト
│   ├── dot_gemini/                  # → ~/.gemini/  (Gemini CLI 設定)
│   │   └── GEMINI.md.tmpl           # 共有テンプレートのエントリーポイント
│   ├── dot_codex/                   # → ~/.codex/   (Codex CLI 設定)
│   │   ├── AGENTS.md.tmpl           # 共有テンプレートのエントリーポイント
│   │   └── run_apply-codex-config.sh  # config.toml 生成スクリプト
│   ├── dot_cursor/                  # → ~/.cursor/  (Cursor 設定)
│   │   └── rules/global.mdc.tmpl    # frontmatter + 共有テンプレート本文
│   ├── dot_zshenv.tmpl              # → ~/.zshenv
│   ├── dot_zprofile.tmpl            # → ~/.zprofile
│   ├── dot_zshrc.tmpl               # → ~/.zshrc
│   └── dot_config/
│       ├── chezmoi/                 # chezmoi 設定
│       ├── ccstatusline/            # → ~/.config/ccstatusline/ (Claude Code ステータスライン)
│       ├── sheldon/plugins.toml     # → ~/.config/sheldon/plugins.toml
│       └── zsh/                     # → ~/.config/zsh/*.zsh
├── tests/
└── docs/                            # 詳細ドキュメント
```

## Common Commands

### make commands

Read @Makefile

### chezmoi commands

Read [docs/tools/chezmoi.md](docs/tools/chezmoi.md)

## 詳細ドキュメント

- [セットアップ](docs/setup.md) — 新規マシンへの手順・トラブルシューティング
- [zsh 設定](docs/zsh.md) — 読み込み順・各ファイルの役割・設定追加方法
- ツール
  - [chezmoi](docs/tools/chezmoi.md) — dotfiles 管理
  - [coding_agents](docs/tools/coding_agents.md) — Coding agents 共通ルール・スキル管理
  - [ccstatusline](docs/tools/ccstatusline.md) — Claude Code ステータスライン
  - [claude_code_hooks](docs/tools/claude_code_hooks.md) — Claude Code hooks（セキュリティ・通知）
  - [sheldon](docs/tools/sheldon.md) — Shell プラグインマネージャ
  - [starship](docs/tools/starship.md) — Shell プロンプト
  - [mise](docs/tools/mise.md) — ランタイムバージョン管理
  - [eza](docs/tools/eza.md) — ls 代替
  - [bat](docs/tools/bat.md) — cat 代替
  - [fzf](docs/tools/fzf.md) — ファジーファインダー
