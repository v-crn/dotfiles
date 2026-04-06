# Coding Agents 設定管理 — 設計仕様

## 概要

`~/.agents/` を共通ルールの中央リポジトリとし、各 coding agents ツール（Claude Code、Codex CLI、Gemini CLI 等）がそれを参照する構成。chezmoi テンプレートで環境差分（OS、WSL、ワークスペース種別、インストール済みツール）を自動的に解決する。

---

## ディレクトリ構造

```text
home/
  .chezmoiscripts/              # chezmoi スクリプト置き場（~/には展開されない）
    .gitkeep
  dot_agents/                   # → ~/.agents/
    AGENTS.md.tmpl              # 環境判定で動的生成されるエントリーポイント
    rules/
      common/                   # 常時適用ルール
        language-policy.md
        markdown-linting.md
        preferred-tools.md
        privacy-policy.md
        web-search.md
      wsl/                      # WSL 固有
        coding-style.md
      macos/                    # macOS 固有（将来追加）
        .gitkeep
      tools/                    # ツール別（将来追加）
        .gitkeep
      workspace/                # ワークスペース別（将来追加）
        .gitkeep
  dot_claude/                   # → ~/.claude/
    CLAUDE.md                   # @~/.agents/AGENTS.md に委譲
    settings.json
  dot_gemini/                   # → ~/.gemini/
    GEMINI.md                   # @~/.agents/AGENTS.md に委譲
  dot_cursor/                   # → ~/.cursor/
    rules/
      global.mdc.tmpl           # 環境判定でルール内容をインライン生成（@ import 非対応のため）
  dot_config/
    ccstatusline/
      settings.json             # Claude Code ステータスライン設定
    chezmoi/
      private_chezmoi.toml.tmpl # workspace 変数を含む（デフォルト: "personal"）
```

---

## AGENTS.md テンプレート設計

`home/dot_agents/AGENTS.md.tmpl` は chezmoi テンプレートとして処理され、環境に応じた `~/.agents/AGENTS.md` を生成する。

### 環境判定マトリクス

| 判定条件 | 手段 | 変数/関数 |
| --- | --- | --- |
| OS 種別 | chezmoi 組み込み | `.chezmoi.os` (`"linux"` / `"darwin"`) |
| WSL 検出 | カーネル情報 | `.chezmoi.kernel.osRelease.id` に `"microsoft"` を含む |
| ワークスペース種別 | `chezmoi.toml` の `[data]` | `.workspace` (string) |
| ツール有無 | chezmoi 組み込み関数 | `lookPath "docker"` 等 |

### テンプレート内容

```tmpl
# AGENTS

# --- Common rules (always applied) ---
- @~/.agents/rules/common/language-policy.md
- @~/.agents/rules/common/markdown-linting.md
- @~/.agents/rules/common/preferred-tools.md
- @~/.agents/rules/common/privacy-policy.md
- @~/.agents/rules/common/web-search.md

# --- OS / Environment specific ---
{{ if eq .chezmoi.os "linux" -}}
{{   if (.chezmoi.kernel.osRelease.id | contains "microsoft") -}}
- @~/.agents/rules/wsl/coding-style.md
{{   end -}}
{{ end -}}
{{ if eq .chezmoi.os "darwin" -}}
- @~/.agents/rules/macos/coding-style.md
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

---

## ツール別委譲ファイル

`~/.agents/AGENTS.md` を単一の信頼できるソースとし、各ツールがそれを参照する。ルールの追加・修正は `~/.agents/` 側のみで完結する。

| ツール | ファイル | 方式 | 備考 |
| --- | --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | `@~/.agents/AGENTS.md` で委譲 | |
| Gemini CLI | `~/.gemini/GEMINI.md` | `@~/.agents/AGENTS.md` で委譲 | グローバル設定: `~/.gemini/GEMINI.md` |
| Codex CLI | `~/.agents/AGENTS.md` | 直接参照 | 追加ファイル不要 |
| Cursor | `~/.cursor/rules/global.mdc` | chezmoi テンプレートでインライン生成 | `@` import 非対応のため `.mdc` 形式で直接埋め込む |

### Cursor `.mdc` ファイルの構造

Cursor はグローバルルールを `~/.cursor/rules/*.mdc` として読み込む（Cursor 0.45+）。ファイル形式：

```markdown
---
description: Global coding rules for all projects
alwaysApply: true
---

（ここに ~/.agents/rules/ の内容を chezmoi テンプレートでインライン展開）
```

`global.mdc.tmpl` は `AGENTS.md.tmpl` と同じ環境判定ロジックを持つが、`@` import の代わりに `{{ includeTemplate }}` 等でルールファイルの内容を直接埋め込む。

---

## chezmoi.toml 設定

`private_chezmoi.toml.tmpl` の `[data]` セクションに `workspace` を追加する。

```toml
[data]
workspace = "personal"   # マシンごとに上書き: "work-acme" 等
```

デフォルトは `"personal"` 。職場マシンでは `~/.config/chezmoi/chezmoi.toml` を直接編集して上書きする。

---

## 修正点

### `~/.claude/CLAUDE.md` パス修正

- **変更前**: `@.agents/AGENTS.md`（`~/.claude/.agents/AGENTS.md` を参照してしまう）
- **変更後**: `@~/.agents/AGENTS.md`（正しい絶対パス）

### `.chezmoiscripts/` への移動

- `home/run_once_set-zsh-config-permissions.sh` → `home/.chezmoiscripts/run_once_set-zsh-config-permissions.sh`
- 公式推奨: スクリプトは `.chezmoiscripts/` に集約することで `~/` にディレクトリが残らない

---

## ドキュメント更新対象

- `README.md` — 動作環境（任意ツールに coding agents 追記）、リポジトリ構成（`dot_agents/`, `dot_claude/`, `ccstatusline/`, `.chezmoiscripts/` 追記）、詳細ドキュメントリンク追加
- `.claude/CLAUDE.md` — リポジトリ構造に `dot_agents/`, `dot_claude/`, `ccstatusline/`, `.chezmoiscripts/` を追記
- `docs/tools/agents.md` — agents 設定の運用ガイドを新規作成（構成・環境判定ルール・ルール追加手順・各ツールの委譲方式）
- `docs/tools/ccstatusline.md` — ccstatusline の設定ファイル場所・カスタマイズ方法を新規作成

---

## 将来のルール追加手順

1. `home/dot_agents/rules/<category>/<tool>.md` を作成
2. `AGENTS.md.tmpl` に判定条件と参照行を追加
3. `chezmoi apply` で `~/.agents/AGENTS.md` を再生成
