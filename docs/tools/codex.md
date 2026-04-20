# OpenAI Codex CLI

OpenAI が提供するターミナル向け AI コーディングエージェント。本ドキュメントは、この dotfiles リポジトリにおける Codex CLI の設定管理方法をまとめたリファレンスである。

## Claude Code との主な違い

| 項目 | Codex CLI | Claude Code |
| --- | --- | --- |
| 提供元 | OpenAI | Anthropic |
| グローバル設定ファイル | `~/.codex/config.toml` | `~/.claude/settings.json` |
| エージェント指示ファイル | `~/.codex/AGENTS.md` | `~/.claude/CLAUDE.md` |
| `@path` インクルード構文 | 非対応 | 対応 |
| フック種別 | post-turn notify のみ | pre/post tool-use など多彩 |
| スキルディレクトリ | `~/.codex/skills/`（`~/.agents/skills/` を直接参照） | `~/.claude/skills/` |

## chezmoi 管理対象ファイル

```text
home/.chezmoitemplates/
  AGENTS.md.tmpl                ← shared rules body for coding agents
home/dot_codex/
  AGENTS.md.tmpl                ← ~/.codex/AGENTS.md（shared template のエントリーポイント）
  hooks/
    executable_notify.sh        ← ~/.codex/hooks/notify.sh
  run_apply-codex-config.sh     ← chezmoi apply 時に実行（ファイルとしては非デプロイ）
```

## config.toml スキーマ（管理ブロック）

`run_apply-codex-config.sh` の `DESIRED` ブロックで管理するキーと意味。

### トップレベルキー

| キー | 設定値 | 説明 |
| --- | --- | --- |
| `model` | `"o4-mini"` | 使用モデルを固定。未設定だと codex がデフォルトを選ぶ |
| `model_reasoning_effort` | `"medium"` | 推論努力量。`"low"` / `"medium"` / `"high"` |
| `approval_policy` | `"on-request"` | ツール実行の承認ポリシー。`"on-request"` / `"auto"` / `"never"` |
| `sandbox_mode` | `"workspace-write"` | サンドボックス制限。`"read-only"` / `"workspace-write"` / `"off"` |
| `personality` | 文字列 | Codex に与えるペルソナ・行動指針の一文 |
| `notify` | `["~/.codex/hooks/notify.sh"]` | ターン終了時に実行するスクリプトのリスト |

### `[tui]` セクション

| キー | 設定値 | 説明 |
| --- | --- | --- |
| `status_line` | 文字列配列 | TUI 下部ステータスバーに表示する項目 |
| `notifications` | `true` | デスクトップ通知を有効化 |
| `notification_condition` | `"always"` | 通知タイミング。`"always"` / `"unfocused"`（デフォルト） |

`status_line` で指定可能な項目の例:

```text
model-with-reasoning  current-dir  git-branch  context-used  context-window-size
```

### `[features]` セクション

| キー | 設定値 | 説明 |
| --- | --- | --- |
| `memories` | `true` | セッション横断メモリを有効化（デフォルト: `false`） |

### `[profiles.*]` セクション

名前付きプロファイル。`codex --profile <name>` で切り替える。

| プロファイル | `approval_policy` | `sandbox_mode` | 用途 |
| --- | --- | --- | --- |
| `conservative` | `on-request` | `read-only` | 本番環境など慎重な操作が必要な場合 |
| `development` | `on-request` | `workspace-write` | 通常の開発作業 |

### 非管理キー（意図的にデフォルト据え置き）

| キー | デフォルト | 理由 |
| --- | --- | --- |
| `web_search` | `"cached"` | キャッシュ検索で十分。変更不要 |

## AGENTS.md

### 役割

`~/.codex/AGENTS.md` は Codex CLI が起動時に読み込むグローバル指示ファイル。すべてのセッションに適用される。

### 生成方法（chezmoi テンプレート）

Codex CLI は Claude Code の `@path` 構文に対応していないため、`chezmoi apply` 時に Go テンプレートでファイルを静的展開する。現在は `home/.chezmoitemplates/AGENTS.md.tmpl` に共通本文を集約し、`home/dot_codex/AGENTS.md.tmpl` はその named template を呼び出すだけの薄いエントリーポイントになっている。

ソース: `home/dot_codex/AGENTS.md.tmpl`

```text
{{ template "AGENTS.md.tmpl" . -}}
```

共通本文側では `home/.chezmoitemplates/assets/agents/rules/` 以下の Markdown ファイルをインライン展開し、`~/.codex/AGENTS.md` として書き出す。

### `@path` が使えない理由

Codex CLI はファイル内の `@path` ディレクティブを解釈しない。そのため `~/.claude/CLAUDE.md` のような実行時委譲はできない。一方でソース管理上は共通化したいため、chezmoi の named template で共有しつつ、生成結果は静的展開にしている。

### プロジェクト別上書き

プロジェクトディレクトリに `AGENTS.override.md` を置くと、chezmoi 管理外の個人用指示として機能する（Git にはコミットしない）。

## 通知フック

### 仕組み

`config.toml` の `notify` キーにスクリプトパスを配列で指定すると、Codex CLI がターン終了時にそのスクリプトを実行する。

```toml
notify = ["~/.codex/hooks/notify.sh"]
```

### `~/.codex/hooks/notify.sh` の実装

```bash
#!/bin/bash
. ~/.agents/hooks/lib/notify.sh
send_notification "Codex" "Finished"
```

共有ライブラリ `~/.agents/hooks/lib/notify.sh` を source するだけのシムスクリプト。

### 共有通知ライブラリ (`~/.agents/hooks/lib/notify.sh`)

Claude Code・Codex CLI が共通で使うプラットフォーム対応の通知関数。

```text
~/.agents/hooks/lib/
  platform.sh   ← PLATFORM 変数を export（macos / wsl / linux / unknown）
  notify.sh     ← send_notification TITLE MESSAGE を提供
```

`send_notification` の挙動:

| プラットフォーム | 通知手段 |
| --- | --- |
| macOS | `osascript` (通知センター) |
| WSL / Linux | `notify-send`（未インストール時は stderr 出力） |
| その他 | stderr 出力 |

## config.toml マージ戦略

### 設計の目的

`config.toml` には dotfiles で管理すべき設定（モデル、サンドボックス設定など）と、環境固有で保持すべき設定（プロジェクト信頼レベル、認証情報）が混在する。awk ベースのマージで両者を分離する。

### 管理セクション vs 保持セクション

| 分類 | 対象 | 動作 |
| --- | --- | --- |
| 管理（毎回上書き） | `model` `model_reasoning_effort` `approval_policy` `sandbox_mode` `personality` `notify` `[tui]` `[features]` `[memories]` `[profiles.*]` | apply のたびに削除・再書き込み |
| 保持（一切触れない） | `[projects.*]` `[auth.*]` `[notice.*]` 未知のセクション | awk で通過させてそのまま維持 |

`[projects.*]` はプロジェクトごとのツール実行信頼レベルが格納されており、環境依存のため dotfiles 管理外とする。

### マージ処理の流れ

1. `~/.codex/config.toml` が存在しない場合: `DESIRED` ブロックをそのまま書き込む
2. 既存ファイルがある場合:
   1. `config.toml.bak` にバックアップ
   2. `awk` で管理キー・管理セクションを除去し、保持コンテンツだけを残す
   3. 末尾の空行を正規化して1行の空行区切りを挿入
   4. `DESIRED` ブロックを末尾に追記
3. `awk` が見つからない場合: 警告を出して終了（ファイルは変更しない）

### 冪等性

apply を何度実行しても結果が同じになるよう設計されている。awk の除去 + 末尾空行の正規化により、適用後のファイル内容は常に一定となる。

## chezmoi インテグレーション

### `run_` スクリプトの動作

`home/dot_codex/run_apply-codex-config.sh` は `run_` プレフィックスにより、`chezmoi apply` を実行するたびに実行される（ファイルとしてはデプロイされない）。

### 適用コマンド

dotfiles リポジトリルートから実行する:

```zsh
# 差分確認
make diff

# 適用（設定ファイル生成・スクリプト実行を含む）
make apply
```

内部的には以下と同等:

```zsh
chezmoi diff --source .
chezmoi apply --source .
```

### テンプレートのレンダリング確認

```zsh
# AGENTS.md の展開結果を確認
chezmoi execute-template --source . < home/dot_codex/AGENTS.md.tmpl

# 共通テンプレート本体を確認
chezmoi execute-template --source . < home/dot_agents/AGENTS.md.tmpl
```

### 適用後の確認

```zsh
# config.toml が正しく生成されているか確認
cat ~/.codex/config.toml

# 通知フックが実行可能か確認
ls -la ~/.codex/hooks/notify.sh
```

## 管理外ファイル

以下は chezmoi の管理対象外。手動またはランタイムが管理する。

| パス | 理由 |
| --- | --- |
| `~/.codex/auth.json` | 認証情報。dotfiles に含めない |
| `~/.codex/memories/` | Codex ランタイムが管理するセッションメモリ |
| `~/.codex/cache/` | ランタイムキャッシュ |
| `~/.codex/skills/.system/` | Codex が自動管理するシステムスキル |

## 関連ドキュメント

- `docs/tools/coding_agents.md` — 複数エージェントの設定共有構成（`~/.agents/` の説明）
- `docs/tools/chezmoi.md` — chezmoi のファイル命名規則と `executable_` プレフィックスの注意点
- `docs/superpowers/specs/2026-04-20-codex-dotfiles-design.md` — 本構成の設計ドキュメント
