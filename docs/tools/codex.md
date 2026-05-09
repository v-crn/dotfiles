# OpenAI Codex CLI

OpenAI が提供するターミナル向け AI コーディングエージェント。本ドキュメントは、この dotfiles リポジトリにおける Codex CLI の設定管理方法をまとめたリファレンスである。

## Claude Code との主な違い

| 項目 | Codex CLI | Claude Code |
| --- | --- | --- |
| 提供元 | OpenAI | Anthropic |
| グローバル設定ファイル | `~/.codex/config.toml` | `~/.claude/settings.json` |
| エージェント指示ファイル | `~/.codex/AGENTS.md` | `~/.claude/CLAUDE.md` |
| `@path` インクルード構文 | 非対応 | 対応 |
| フック種別 | `hooks.json` による `PreToolUse` / `Stop` など + `features.hooks` | pre/post tool-use など多彩 |
| スキルディレクトリ | `~/.codex/skills/`（`~/.agents/skills/` を直接参照） | `~/.claude/skills/` |

## chezmoi 管理対象ファイル

```text
home/.chezmoitemplates/
  AGENTS.md.tmpl                ← shared rules body for coding agents
home/dot_codex/
  AGENTS.md.tmpl                ← ~/.codex/AGENTS.md（shared template のエントリーポイント）
  hooks/
    executable_pre-tool-use.sh   ← ~/.codex/hooks/pre-tool-use.sh
    executable_stop.sh           ← ~/.codex/hooks/stop.sh
    executable_notify.sh        ← ~/.codex/hooks/notify.sh（legacy）
  private_hooks.json.tmpl        ← ~/.codex/hooks.json
  run_apply-codex-config.sh     ← chezmoi apply 時に実行（ファイルとしては非デプロイ）
```

## config.toml スキーマ（管理ブロック）

`run_apply-codex-config.sh` の `DESIRED` ブロックで管理するキーと意味。

### トップレベルキー

| キー | 管理方針 | 説明 |
| --- | --- | --- |
| `model` | ユーザー管理 | dotfiles では固定しない。未設定なら Codex 側のデフォルトが使われる |
| `approval_policy` | `"on-request"` に固定 | ツール実行の承認ポリシー |
| `sandbox_mode` | `"workspace-write"` に固定 | サンドボックス制限 |
| `service_tier` | コメント例のみ | 例として template に載せるが、通常は未設定のままにする |
| `model_reasoning_effort` | `"medium"` に固定 | 推論努力量 |
| `personality` | `"pragmatic"` に固定 | 通常時の対話スタイル |
| `model_context_window` | コメント例のみ | 手動のコンテキスト窓上書き例。active な既存値は apply で削除する |
| `model_auto_compact_token_limit` | コメント例のみ | 自動 compact 閾値の上書き例。active な既存値は apply で削除する |
| `tool_output_token_limit` | コメント例のみ | ツール出力保持トークン数の上書き例。active な既存値は apply で削除する |
| `background_terminal_max_timeout` | コメント例のみ | バックグラウンド端末 poll timeout の上書き例。active な既存値は apply で削除する |
| `log_dir` | コメント例のみ | ログ保存先の上書き例。active な既存値は apply で削除する |
| `sqlite_home` | コメント例のみ | SQLite state ディレクトリの上書き例。active な既存値は apply で削除する |
| `notify` | コメント例のみ | 外部 notifier の例。active な既存値は apply で削除する |

### `[tui]` セクション

| キー | 管理方針 | 説明 |
| --- | --- | --- |
| `status_line` | 下記配列に固定 | TUI 下部ステータスバーに表示する項目 |
| `notifications` | `true` に固定 | デスクトップ通知を有効化 |
| `notification_condition` | `"always"` に固定 | 通知タイミング |

`status_line` の管理値:

```text
model-with-reasoning  git-branch  context-used  context-window-size
used-tokens  five-hour-limit  weekly-limit
```

### `[features]` セクション

| キー | 設定値 | 説明 |
| --- | --- | --- |
| `memories` | `true` | セッション横断メモリを有効化（デフォルト: `false`） |
| `hooks` | `true` | グローバル `hooks.json` の読み込みを有効化 |

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

`Stop` は現在の completion hook で、dotfiles ではこれを管理対象としている。
`notify` は旧方式で、既存環境に残っていても `run_apply-codex-config.sh` が削除する。

### `~/.codex/hooks/notify.sh` の実装

```bash
#!/bin/bash
. ~/.agents/hooks/lib/notify.sh
send_notification "Codex" "Finished"
```

共有ライブラリ `~/.agents/hooks/lib/notify.sh` を source するだけのシムスクリプト。現行の Codex グローバル hooks では直接は使わない。

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

## Global Hooks

Codex CLI は `~/.codex/hooks.json` からグローバル hooks を読み込む。dotfiles では
`home/dot_codex/private_hooks.json.tmpl` を `~/.codex/hooks.json` にデプロイし、
`~/.codex/hooks/pre-tool-use.sh` と `~/.codex/hooks/stop.sh` の薄いアダプタから
`~/.agents/hooks/bin/` の shared core を呼び出す。

`PreToolUse` は現状 `Bash` のみを対象にしている。Codex 側の matcher も Bash に
絞っており、Claude の `Read|Edit|Write` のような広い防御はまだ行わない。

共有 Bash ポリシーは common-case の guardrail であり、完全な shell parser や
security boundary ではない。頻出の危険パターンを実用上の粒度で止めることを優先し、
曖昧な入力は安全側に倒す。

`Stop` は shared notifier に委譲し、`stop_hook_active` のループ回避はアダプタ側で
最小限だけ扱う。

## config.toml マージ戦略

### 設計の目的

`config.toml` には dotfiles で管理すべき設定（承認ポリシー、`[tui]`、`[features]` など）と、環境固有で保持すべき設定（モデル、プロジェクト信頼レベル、認証情報）が混在する。awk ベースのマージで両者を分離する。

### 管理セクション vs 保持セクション

| 分類 | 対象 | 動作 |
| --- | --- | --- |
| 管理（毎回上書き） | `model_reasoning_effort` `approval_policy` `sandbox_mode` `personality` `[tui]` `[features]` `[profiles.*]` | apply のたびに削除・再書き込み |
| 管理されたコメント例 | `service_tier` `model_context_window` `model_auto_compact_token_limit` `tool_output_token_limit` `background_terminal_max_timeout` `log_dir` `sqlite_home` `notify` | template にはコメントで出す。active な既存値は apply のたびに削除する |
| 保持（一切触れない） | `model` `[projects.*]` `[auth.*]` `[notice.*]` 未知のセクション | awk で通過させてそのまま維持 |

`[projects.*]` はプロジェクトごとのツール実行信頼レベルが格納されており、環境依存のため dotfiles 管理外とする。

### マージ処理の流れ

1. `~/.codex/config.toml` が存在しない場合: curated template をそのまま書き込む
2. 既存ファイルがある場合:
   1. `config.toml.bak` にバックアップ。バックアップ作成に失敗した場合はその場で中断する
   2. `awk` で active な管理キー、`[tui]` / `[features]` / `[profiles.*]`、旧 `notify` を除去する
   3. 末尾の空行を正規化して1行の空行区切りを挿入
   4. curated block を末尾に追記する
3. `awk` が見つからない場合: 警告を出して終了（ファイルは変更しない）

### 冪等性

apply を何度実行しても結果が同じになるよう設計されている。active な管理項目だけを除去して curated block を再追記するため、出力は一定になる。

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

# グローバル hooks の内容を確認
jq '.hooks.PreToolUse[0].matcher, .hooks.Stop[0].hooks[0].command' ~/.codex/hooks.json

# アダプタが実行可能か確認
ls -la ~/.codex/hooks/pre-tool-use.sh ~/.codex/hooks/stop.sh
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
