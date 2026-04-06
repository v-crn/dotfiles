# Coding Agents Config 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `~/.agents/` を中央ルールリポジトリとし、Claude Code / Gemini CLI / Cursor / Codex CLI が共通設定を参照する chezmoi 管理構成を構築する。

**Architecture:** `home/dot_agents/AGENTS.md.tmpl` が chezmoi テンプレートとして OS・WSL・ワークスペース・ツール有無を判定し環境固有の `~/.agents/AGENTS.md` を生成する。Claude Code と Gemini CLI は `@~/.agents/AGENTS.md` で委譲し、Cursor は `@` import 非対応のため `global.mdc.tmpl` でルール内容をインラインに展開する。

**Tech Stack:** chezmoi (Go テンプレート・sprig 関数)、Markdown

---

## ファイルマップ

| 操作 | パス | 役割 |
| --- | --- | --- |
| 新規 | `home/.chezmoiscripts/.gitkeep` | スクリプト置き場ディレクトリを Git 追跡 |
| 移動 | `home/run_once_set-zsh-config-permissions.sh` → `home/.chezmoiscripts/` | 公式推奨構成へ移行 |
| リネーム+編集 | `home/dot_agents/AGENTS.md` → `AGENTS.md.tmpl` | 環境判定テンプレート化 |
| 新規 | `home/dot_agents/rules/macos/.gitkeep` | 将来の macOS ルール用 |
| 新規 | `home/dot_agents/rules/tools/.gitkeep` | 将来のツール別ルール用 |
| 新規 | `home/dot_agents/rules/workspace/.gitkeep` | 将来のワークスペース別ルール用 |
| 編集 | `home/dot_claude/CLAUDE.md` | `@` import パス修正 |
| 新規 | `home/dot_gemini/GEMINI.md` | Gemini CLI 委譲ファイル |
| 新規 | `home/dot_cursor/rules/global.mdc.tmpl` | Cursor グローバルルール（インライン展開） |
| 編集 | `home/dot_config/chezmoi/private_chezmoi.toml.tmpl` | `workspace` 変数を追加 |
| 編集 | `README.md` | 動作環境・構成・ドキュメントリンクを更新 |
| 編集 | `.claude/CLAUDE.md` | リポジトリ構造を更新 |
| 新規 | `docs/tools/agents.md` | agents 設定運用ガイド |
| 新規 | `docs/tools/ccstatusline.md` | ccstatusline 設定ガイド |

---

### Task 1: `.chezmoiscripts/` の整備とスクリプト移動

**Files:**
- Create: `home/.chezmoiscripts/.gitkeep`
- Move: `home/run_once_set-zsh-config-permissions.sh` → `home/.chezmoiscripts/run_once_set-zsh-config-permissions.sh`
- Delete: `home/run_once_set-zsh-config-permissions.sh`

**背景:** chezmoi 公式推奨では、スクリプトは `home/` 直下でなく `.chezmoiscripts/` に置くことで `~/` にディレクトリが残らない。`run_once_` プレフィックスは移動後も効果を保つ。

- [ ] **Step 1: `.gitkeep` を作成**

```bash
touch home/.chezmoiscripts/.gitkeep
```

- [ ] **Step 2: スクリプトを移動**

```bash
git mv home/run_once_set-zsh-config-permissions.sh home/.chezmoiscripts/run_once_set-zsh-config-permissions.sh
```

- [ ] **Step 3: 内容を確認（移動後も変わらないことを確認）**

```bash
cat home/.chezmoiscripts/run_once_set-zsh-config-permissions.sh
```

期待出力:

```text
#!/usr/bin/env zsh
# Run once: restrict ~/.config/zsh permissions to owner-only
chmod 700 "${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
```

- [ ] **Step 4: コミット**

```bash
git add home/.chezmoiscripts/.gitkeep
git commit -m "refactor: move scripts to .chezmoiscripts per chezmoi convention"
```

---

### Task 2: 空ディレクトリに `.gitkeep` を追加

**Files:**
- Create: `home/dot_agents/rules/macos/.gitkeep`
- Create: `home/dot_agents/rules/tools/.gitkeep`
- Create: `home/dot_agents/rules/workspace/.gitkeep`

- [ ] **Step 1: `.gitkeep` を3つ作成**

```bash
touch home/dot_agents/rules/macos/.gitkeep
touch home/dot_agents/rules/tools/.gitkeep
touch home/dot_agents/rules/workspace/.gitkeep
```

- [ ] **Step 2: コミット**

```bash
git add home/dot_agents/rules/macos/.gitkeep \
        home/dot_agents/rules/tools/.gitkeep \
        home/dot_agents/rules/workspace/.gitkeep
git commit -m "chore: add .gitkeep for future rules directories"
```

---

### Task 3: `AGENTS.md` をテンプレート化

**Files:**
- Delete: `home/dot_agents/AGENTS.md`
- Create: `home/dot_agents/AGENTS.md.tmpl`

**背景:**
- `chezmoi.kernel.osrelease` は Linux カーネルのバージョン文字列（例: `5.15.90.1-microsoft-standard-WSL2`）。WSL2 では `"microsoft"` を含む
- `lookPath` は `$PATH` からコマンドを探す chezmoi/sprig 組み込み関数。見つからない場合は空文字を返す
- `darwin` セクションは現時点でルールファイルが未存在のためコメントアウト

- [ ] **Step 1: 既存 `AGENTS.md` を削除して `.tmpl` を作成**

`home/dot_agents/AGENTS.md` を削除し、`home/dot_agents/AGENTS.md.tmpl` を以下の内容で作成する:

```
# AGENTS

# --- Common rules (always applied) ---
- @~/.agents/rules/common/language-policy.md
- @~/.agents/rules/common/markdown-linting.md
- @~/.agents/rules/common/preferred-tools.md
- @~/.agents/rules/common/privacy-policy.md
- @~/.agents/rules/common/web-search.md

# --- OS / Environment specific ---
{{ if eq .chezmoi.os "linux" -}}
{{   if contains "microsoft" .chezmoi.kernel.osrelease -}}
- @~/.agents/rules/wsl/coding-style.md
{{   end -}}
{{ end -}}

# --- Workspace specific ---
{{ if ne .workspace "personal" -}}
- @~/.agents/rules/workspace/{{ .workspace }}.md
{{ end -}}

# --- Tool specific (auto-detected) ---
{{ if lookPath "docker" -}}
- @~/.agents/rules/tools/docker.md
{{ end -}}
{{ if lookPath "gcloud" -}}
- @~/.agents/rules/tools/gcloud.md
{{ end -}}
```

- [ ] **Step 2: テンプレートのレンダリングを確認**

```bash
chezmoi execute-template < home/dot_agents/AGENTS.md.tmpl
```

WSL 環境での期待出力（docker/gcloud 未インストールの場合）:

```text
# AGENTS

# --- Common rules (always applied) ---
- @~/.agents/rules/common/language-policy.md
- @~/.agents/rules/common/markdown-linting.md
- @~/.agents/rules/common/preferred-tools.md
- @~/.agents/rules/common/privacy-policy.md
- @~/.agents/rules/common/web-search.md

# --- OS / Environment specific ---
- @~/.agents/rules/wsl/coding-style.md
```

- [ ] **Step 3: コミット**

```bash
git rm home/dot_agents/AGENTS.md
git add home/dot_agents/AGENTS.md.tmpl
git commit -m "feat: convert AGENTS.md to chezmoi template with env detection"
```

---

### Task 4: `CLAUDE.md` パス修正 と `GEMINI.md` 作成

**Files:**
- Edit: `home/dot_claude/CLAUDE.md`
- Create: `home/dot_gemini/GEMINI.md`

**背景:** `home/dot_claude/CLAUDE.md` の `@.agents/AGENTS.md` は `~/.claude/` からの相対パスで解決されるため `~/.claude/.agents/AGENTS.md` を指してしまう。正しくは絶対パス `@~/.agents/AGENTS.md` が必要。

- [ ] **Step 1: `CLAUDE.md` のパスを修正**

`home/dot_claude/CLAUDE.md` の内容を以下に変更する:

```markdown
# CLAUDE

@~/.agents/AGENTS.md
```

- [ ] **Step 2: `dot_gemini/GEMINI.md` を作成**

`home/dot_gemini/GEMINI.md` を以下の内容で新規作成する:

```markdown
# GEMINI

@~/.agents/AGENTS.md
```

- [ ] **Step 3: コミット**

```bash
git add home/dot_claude/CLAUDE.md home/dot_gemini/GEMINI.md
git commit -m "fix: correct CLAUDE.md import path and add GEMINI.md delegation"
```

---

### Task 5: Cursor `global.mdc.tmpl` の作成

**Files:**
- Create: `home/dot_cursor/rules/global.mdc.tmpl`

**背景:** Cursor は `~/.cursor/rules/*.mdc` をグローバルルールとして読み込む（Cursor 0.45+）。`.mdc` は YAML frontmatter + Markdown 形式で `@` import 未対応。chezmoi の `include` 関数でルールファイルの内容を直接展開する。`include` のパスは chezmoi ソースルート（`home/` ディレクトリ）からの相対パス。

- [ ] **Step 1: `global.mdc.tmpl` を作成**

`home/dot_cursor/rules/global.mdc.tmpl` を以下の内容で新規作成する:

```
---
description: Global coding rules for all projects
alwaysApply: true
---

{{ include "dot_agents/rules/common/language-policy.md" }}

{{ include "dot_agents/rules/common/markdown-linting.md" }}

{{ include "dot_agents/rules/common/preferred-tools.md" }}

{{ include "dot_agents/rules/common/privacy-policy.md" }}

{{ include "dot_agents/rules/common/web-search.md" }}

{{ if eq .chezmoi.os "linux" -}}
{{   if contains "microsoft" .chezmoi.kernel.osrelease -}}
{{ include "dot_agents/rules/wsl/coding-style.md" }}
{{   end -}}
{{ end -}}

{{ if ne .workspace "personal" -}}
{{ include (printf "dot_agents/rules/workspace/%s.md" .workspace) }}
{{ end -}}

{{ if lookPath "docker" -}}
{{ include "dot_agents/rules/tools/docker.md" }}
{{ end -}}

{{ if lookPath "gcloud" -}}
{{ include "dot_agents/rules/tools/gcloud.md" }}
{{ end -}}
```

- [ ] **Step 2: テンプレートのレンダリングを確認**

```bash
chezmoi execute-template < home/dot_cursor/rules/global.mdc.tmpl
```

期待出力（先頭部分）:

```text
---
description: Global coding rules for all projects
alwaysApply: true
---

# Language Policy
...
```

- [ ] **Step 3: コミット**

```bash
git add home/dot_cursor/rules/global.mdc.tmpl
git commit -m "feat: add Cursor global rules template with inline rule expansion"
```

---

### Task 6: `private_chezmoi.toml.tmpl` に `workspace` 変数を追加

**Files:**
- Edit: `home/dot_config/chezmoi/private_chezmoi.toml.tmpl`

- [ ] **Step 1: `workspace` 変数を追加**

`home/dot_config/chezmoi/private_chezmoi.toml.tmpl` の `[data]` セクションを以下に変更する:

```toml
# SECURITY: This file is committed to git. Never place secrets, tokens,
# API keys, passwords, or sensitive personal data here.
# Machine-specific secrets belong in ~/.config/chezmoi/chezmoi.toml (untracked).

[data]
# Use boolean flags for branching — avoid literal personal identifiers.
# Example: isWork = false

# Workspace type: "personal" (default) or a workplace identifier e.g. "work-acme"
# Override per machine in ~/.config/chezmoi/chezmoi.toml
workspace = "personal"
```

- [ ] **Step 2: テンプレート変数が利用可能なことを確認**

```bash
chezmoi data | grep workspace
```

期待出力:

```text
  "workspace": "personal",
```

- [ ] **Step 3: コミット**

```bash
git add home/dot_config/chezmoi/private_chezmoi.toml.tmpl
git commit -m "feat: add workspace variable to chezmoi.toml template"
```

---

### Task 7: `README.md` の更新

**Files:**
- Edit: `README.md`

- [ ] **Step 1: `README.md` を更新**

`README.md` を以下の内容に置き換える:

```markdown
# dotfiles

chezmoi で管理する個人 dotfiles。WSL2 / macOS / Linux で動く zsh 環境と coding agents の共通設定を再現する。

## 動作環境

| 必須 | 任意 (なくても起動は壊れない) |
| --- | --- |
| zsh | eza, bat / batcat, fzf |
| chezmoi | mise, sheldon, starship |
| | Claude Code, Gemini CLI, Cursor (coding agents) |

## クイックスタート

\`\`\`zsh
git clone <repo-url> ~/dotfiles
chezmoi init --source ~/dotfiles
chezmoi diff          # 変更内容を確認
chezmoi apply         # 適用
\`\`\`

sheldon を使う場合はプラグインをダウンロード:

\`\`\`zsh
sheldon lock
\`\`\`

## リポジトリ構成

\`\`\`text
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
\`\`\`

## よく使うコマンド

\`\`\`zsh
chezmoi diff                     # 差分確認
chezmoi apply                    # 適用
chezmoi edit ~/.zshrc            # マネージドファイルを編集して適用
chezmoi add ~/.<file>            # 新しいファイルを管理対象に追加
chezmoi managed                  # 管理対象ファイル一覧
chezmoi execute-template < home/dot_agents/AGENTS.md.tmpl  # テンプレート確認
bats tests/                      # テスト実行
\`\`\`

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
```

- [ ] **Step 2: Markdown lint を実行**

```bash
markdownlint-cli2 --fix README.md
```

エラーがなければ OK。

- [ ] **Step 3: コミット**

```bash
git add README.md
git commit -m "docs: update README with coding agents and new structure"
```

---

### Task 8: `.claude/CLAUDE.md` のリポジトリ構造を更新

**Files:**
- Edit: `.claude/CLAUDE.md`

- [ ] **Step 1: Repository Structure セクションを更新**

`.claude/CLAUDE.md` の `## Repository Structure` 内のツリーを以下に置き換える（`home/` 内の関連部分）:

```text
dotfiles/
├── .chezmoiroot                          # Points chezmoi source root to "home/"
├── .gitignore
├── .claude/
│   └── CLAUDE.md                         # This file
├── home/                                 # chezmoi source root
│   ├── .chezmoiscripts/                  # Scripts run by chezmoi (not deployed to ~/)
│   │   └── run_once_set-zsh-config-permissions.sh
│   ├── dot_agents/                       # -> ~/.agents/  (coding agents shared rules)
│   │   ├── AGENTS.md.tmpl                # Entry point — env-aware, generated by chezmoi
│   │   └── rules/
│   │       ├── common/                   # Always-applied rules
│   │       ├── wsl/                      # WSL-specific rules
│   │       ├── macos/                    # macOS-specific rules (future)
│   │       ├── tools/                    # Tool-specific rules (future)
│   │       └── workspace/               # Workspace-specific rules (future)
│   ├── dot_claude/                       # -> ~/.claude/
│   │   ├── CLAUDE.md                     # Delegates to @~/.agents/AGENTS.md
│   │   └── settings.json
│   ├── dot_gemini/                       # -> ~/.gemini/
│   │   └── GEMINI.md                     # Delegates to @~/.agents/AGENTS.md
│   ├── dot_cursor/                       # -> ~/.cursor/
│   │   └── rules/
│   │       └── global.mdc.tmpl           # Cursor global rules (inline expansion)
│   ├── dot_zshenv.tmpl                   # -> ~/.zshenv  (all shells: XDG, EDITOR, LANG)
│   ├── dot_zprofile.tmpl                 # -> ~/.zprofile  (login shells: PATH, Homebrew)
│   ├── dot_zshrc.tmpl                    # -> ~/.zshrc  (interactive shells: sources config/)
│   ├── dot_config/
│   │   ├── chezmoi/
│   │   │   └── private_chezmoi.toml.tmpl # -> ~/.config/chezmoi/chezmoi.toml (0600)
│   │   ├── ccstatusline/
│   │   │   └── settings.json             # -> ~/.config/ccstatusline/settings.json
│   │   ├── sheldon/
│   │   │   └── plugins.toml              # -> ~/.config/sheldon/plugins.toml
│   │   ├── zsh/                          # Glob-loaded by ~/.zshrc (alphabetical order)
│   │   │   ├── ...
│   │   └── starship.toml                 # -> ~/.config/starship.toml
├── tests/
│   └── test_zsh.bats                     # Shell tests (bats-core)
└── docs/
    ├── setup.md
    ├── zsh.md
    ├── tools/
    │   ├── agents.md                     # Coding agents rules guide
    │   ├── ccstatusline.md               # Claude Code status line guide
    │   └── ...
    └── superpowers/
        ├── specs/
        └── plans/
```

- [ ] **Step 2: コミット**

```bash
git add .claude/CLAUDE.md
git commit -m "docs: update CLAUDE.md repository structure for agents config"
```

---

### Task 9: `docs/tools/agents.md` の作成

**Files:**
- Create: `docs/tools/agents.md`

- [ ] **Step 1: `agents.md` を作成**

`docs/tools/agents.md` を以下の内容で新規作成する:

```markdown
# Coding Agents 設定管理

`~/.agents/` を共通ルールのリポジトリとして、複数の coding agents ツールが設定を共有する構成。

## 構成

\`\`\`text
~/.agents/
├── AGENTS.md          # エントリーポイント（chezmoi が環境に合わせて生成）
└── rules/
    ├── common/        # 常時適用ルール
    ├── wsl/           # WSL 固有ルール
    ├── macos/         # macOS 固有ルール（将来）
    ├── tools/         # ツール別ルール（将来）
    └── workspace/     # ワークスペース別ルール（将来）
\`\`\`

## 各ツールの参照方式

| ツール | ファイル | 方式 |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | `@~/.agents/AGENTS.md` で委譲 |
| Gemini CLI | `~/.gemini/GEMINI.md` | `@~/.agents/AGENTS.md` で委譲 |
| Codex CLI | `~/.agents/AGENTS.md` | 直接参照 |
| Cursor | `~/.cursor/rules/global.mdc` | chezmoi テンプレートでインライン展開 |

## 環境判定ロジック

`~/.agents/AGENTS.md` は chezmoi テンプレート（`home/dot_agents/AGENTS.md.tmpl`）から生成される。

| 条件 | 判定方法 | 追加されるルール |
| --- | --- | --- |
| WSL 環境 | `chezmoi.kernel.osrelease` に `"microsoft"` を含む | `rules/wsl/coding-style.md` |
| 非 personal ワークスペース | `workspace != "personal"`（`chezmoi.toml` で設定） | `rules/workspace/<name>.md` |
| docker インストール済み | `lookPath "docker"` | `rules/tools/docker.md` |
| gcloud インストール済み | `lookPath "gcloud"` | `rules/tools/gcloud.md` |

## ワークスペース設定

デフォルトは `"personal"`。職場マシンでは `~/.config/chezmoi/chezmoi.toml` に以下を追記する（Git 管理外）:

\`\`\`toml
[data]
workspace = "work-acme"
\`\`\`

対応するルールファイル `home/dot_agents/rules/workspace/work-acme.md` を作成し、`chezmoi apply` を実行する。

## ルール追加手順

1. `home/dot_agents/rules/<category>/<name>.md` を作成
2. 必要に応じて `home/dot_agents/AGENTS.md.tmpl` に判定条件と参照行を追加
3. Cursor も更新が必要な場合は `home/dot_cursor/rules/global.mdc.tmpl` も編集
4. `chezmoi execute-template < home/dot_agents/AGENTS.md.tmpl` でレンダリングを確認
5. `chezmoi apply` で反映

## テンプレートの確認コマンド

\`\`\`zsh
# AGENTS.md のレンダリング確認
chezmoi execute-template < home/dot_agents/AGENTS.md.tmpl

# 現在の環境変数（chezmoi テンプレート変数）を確認
chezmoi data

# 適用前の差分確認
chezmoi diff
\`\`\`
```

- [ ] **Step 2: Markdown lint**

```bash
markdownlint-cli2 --fix docs/tools/agents.md
```

- [ ] **Step 3: コミット**

```bash
git add docs/tools/agents.md
git commit -m "docs: add coding agents setup guide"
```

---

### Task 10: `docs/tools/ccstatusline.md` の作成

**Files:**
- Create: `docs/tools/ccstatusline.md`

- [ ] **Step 1: `ccstatusline.md` を作成**

`docs/tools/ccstatusline.md` を以下の内容で新規作成する:

```markdown
# ccstatusline

Claude Code のステータスラインをカスタマイズするツール。

## 概要

[ccstatusline](https://github.com/hcavarsan/ccstatusline) は Claude Code のステータスバーに表示する情報をカスタマイズできる CLI ツール。モデル名・思考量・コンテキスト使用率・トークン数・Git 情報などをステータスラインに表示する。

## 設定ファイル

| ファイル | 用途 |
| --- | --- |
| `~/.config/ccstatusline/settings.json` | 表示レイアウト・色・各ウィジェットの設定 |

chezmoi ソース: `home/dot_config/ccstatusline/settings.json`

## Claude Code への組み込み

`~/.claude/settings.json` の `statusLine` セクションで設定する:

\`\`\`json
{
  "statusLine": {
    "type": "command",
    "command": "npx -y ccstatusline@latest",
    "padding": 0
  }
}
\`\`\`

## ウィジェット一覧

| type | 表示内容 |
| --- | --- |
| `model` | 使用中のモデル名 |
| `thinking-effort` | 思考モードの設定値 |
| `context-percentage` | コンテキストウィンドウ使用率 |
| `session-usage` | セッション内トークン使用量 |
| `tokens-total` | 累計トークン数 |
| `tokens-cached` | キャッシュ済みトークン数 |
| `weekly-usage` | 週次トークン使用量 |
| `reset-timer` | セッションリセットまでの残り時間 |
| `weekly-reset-timer` | 週次リセットまでの残り時間 |
| `git-root-dir` | Git リポジトリ名 |
| `git-branch` | 現在のブランチ名 |
| `git-changes` | 変更ファイル数 |
| `git-worktree` | worktree 名 |
| `skills` | ロード済みスキル数 |
| `separator` | 区切り文字 |

## 設定のカスタマイズ

`settings.json` を編集後、`chezmoi apply` で `~/.config/ccstatusline/settings.json` に反映する:

\`\`\`zsh
# 設定ファイルを直接編集
$EDITOR home/dot_config/ccstatusline/settings.json

# 反映
chezmoi apply
\`\`\`
```

- [ ] **Step 2: Markdown lint**

```bash
markdownlint-cli2 --fix docs/tools/ccstatusline.md
```

- [ ] **Step 3: コミット**

```bash
git add docs/tools/ccstatusline.md
git commit -m "docs: add ccstatusline setup guide"
```

---

### Task 11: 最終確認

- [ ] **Step 1: `chezmoi diff` で差分を確認**

```bash
chezmoi diff
```

期待: 新規ファイルの追加と既存ファイルの変更が表示される。エラーがないことを確認。

- [ ] **Step 2: テンプレートの動作確認**

```bash
chezmoi execute-template < home/dot_agents/AGENTS.md.tmpl
chezmoi execute-template < home/dot_cursor/rules/global.mdc.tmpl
```

期待: WSL 環境の場合、WSL ルールが含まれた出力が表示される。

- [ ] **Step 3: chezmoi data で `workspace` 変数を確認**

```bash
chezmoi data | grep workspace
```

期待出力:

```text
  "workspace": "personal",
```

- [ ] **Step 4: 既存テストを実行**

```bash
bats tests/
```

期待: 全テストが PASS する。
