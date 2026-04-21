# Coding Agents 設定管理

`~/.agents/` を共通ルール・スキルのリポジトリとして、複数の coding agents ツールが設定を共有する構成。

## 構成

```text
~/.agents/
├── AGENTS.md          # エントリーポイント（chezmoi が環境に合わせて生成）
└── skills/            # 共有スキル（エージェントが on-demand でロード）
    └── <skill-name>/
        └── SKILL.md
```

ルール本文の共通ソースは `home/.chezmoitemplates/AGENTS.md.tmpl` に集約されている。`home/dot_agents/AGENTS.md.tmpl`、`home/dot_claude/CLAUDE.md.tmpl`、`home/dot_gemini/GEMINI.md.tmpl`、`home/dot_codex/AGENTS.md.tmpl` はこの named template を呼ぶ薄いエントリーポイントで、`home/dot_cursor/rules/global.mdc.tmpl` は frontmatter を付けたうえで同じ本文をインライン展開する。

## Shared Hooks

`~/.agents/hooks/` を coding agent 向け hook の共通基盤として使う。

| 区分 | パス | 用途 |
| --- | --- | --- |
| Shared core | `~/.agents/hooks/lib/` | `.env` 判定、危険 Bash 判定、signal runtime |
| Shared entrypoints | `~/.agents/hooks/bin/` | `check-preflight.sh` `agent-signal.sh` `agent-attention.sh` `agent-finished.sh` `agent-danger.sh` |
| Agent adapters | `~/.claude/hooks/` `~/.codex/hooks/` `~/.gemini/hooks/` | 各ツール固有の stdin/stdout 変換 |

共有コアには判定ロジックと signal 実装を集約し、各エージェント配下の hook は薄い adapter として入力形式の違いだけを吸収する。これにより、ポリシー変更や toast/sound 経路の変更は `~/.agents/hooks/` 側で一元管理できる。

## 各ツールの参照方式

### ルール

| ツール | ファイル | 方式 |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | `@~/.agents/AGENTS.md` で委譲 |
| Gemini CLI | `~/.gemini/GEMINI.md` | `@~/.agents/AGENTS.md` で委譲 |
| Codex CLI | `~/.agents/AGENTS.md` | 直接参照 |
| Cursor | `~/.cursor/rules/global.mdc` | chezmoi テンプレートでインライン展開 |

### スキル

| ツール | ディレクトリ | 方式 |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` | `~/.agents/skills/` へのシンボリックリンク |
| Gemini CLI | `~/.gemini/skills/` | `~/.agents/skills/` へのシンボリックリンク |
| Codex CLI | `~/.agents/skills/` | 直接参照 |

シンボリックリンクは `chezmoi apply` 時に `.chezmoiscripts/run_always_link-agent-skills.sh` が自動作成する。

## 環境判定ロジック

`~/.agents/AGENTS.md` は `home/dot_agents/AGENTS.md.tmpl` から生成されるが、実体のルール本文は `home/.chezmoitemplates/AGENTS.md.tmpl` にある。

| 条件 | 判定方法 | 追加されるルール |
| --- | --- | --- |
| WSL 環境 | `chezmoi.kernel.osrelease` に `"microsoft"` を含む。実行時 hook では `WSL_DISTRO_NAME` と Linux kernel の `osrelease` / `version` も併用する | `assets/agents/rules/wsl/coding-style.md` |
| 非 personal ワークスペース | `workspace != "personal"`（`chezmoi.toml` で設定） | `assets/agents/rules/workspace/<name>.md` |

## ワークスペース設定

デフォルトは `"personal"`。職場マシンでは `~/.config/chezmoi/chezmoi.toml` に以下を追記する（Git 管理外）:

```toml
[data]
workspace = "work-acme"
```

対応するルールファイル `home/.chezmoitemplates/assets/agents/rules/workspace/work-acme.md` を作成し、`make apply` を実行する。

## ルール追加手順

1. `home/.chezmoitemplates/assets/agents/rules/<category>/<name>.md` を作成
2. 必要に応じて `home/.chezmoitemplates/AGENTS.md.tmpl` に判定条件と参照行を追加
3. `chezmoi execute-template --source . < home/dot_agents/AGENTS.md.tmpl` でレンダリングを確認
4. `chezmoi execute-template --source . < home/dot_cursor/rules/global.mdc.tmpl` で Cursor 向け展開も確認
5. `make apply` で反映（dotfiles リポジトリルートから実行）

## スキル追加手順

1. `home/dot_agents/skills/<skill-name>/SKILL.md` を作成（YAML frontmatter に `name` と `description` 必須）
2. dotfiles リポジトリルートで `make apply` を実行
   - `~/.agents/skills/<skill-name>/` がデプロイされる
   - `run_always_link-agent-skills.sh` が `~/.claude/skills/` と `~/.gemini/skills/` にシンボリックリンクを自動作成する

```zsh
# 確認
ls ~/.claude/skills/
ls ~/.gemini/skills/
```

## テンプレートの確認コマンド

```zsh
# AGENTS.md のレンダリング確認（dotfiles リポジトリルートから実行）
chezmoi execute-template --source . < home/dot_agents/AGENTS.md.tmpl

# Cursor ルールのレンダリング確認
chezmoi execute-template --source . < home/dot_cursor/rules/global.mdc.tmpl

# 現在の環境変数（chezmoi テンプレート変数）を確認
chezmoi data

# 適用前の差分確認
make diff

# 適用
make apply
```
