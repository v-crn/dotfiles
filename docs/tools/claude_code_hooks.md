# Claude Code Hooks

Claude Code の hooks 機能を使い、セキュリティと通知の自動化を実装している。

`~/.claude/CLAUDE.md` 自体は `home/dot_claude/CLAUDE.md.tmpl` から生成され、共通ルール本文は `home/.chezmoitemplates/AGENTS.md.tmpl` を参照する。hooks はこの共有ルール構成とは独立して `~/.claude/settings.json` に統合される。

## 概要

| Hook 種別 | トリガー | 動作 |
| --- | --- | --- |
| `PreToolUse` | ツール呼び出し前 | Claude アダプタが共有 preflight core を呼び出し、危険な Bash deny 時だけ danger signal を鳴らしてからブロック |
| `Notification` | Claude が入力待ち・承認待ちになったとき | Claude アダプタが共有 signal runtime の `attention` を呼び出す |
| `Stop` | Claude がレスポンスを完了したとき | Claude 固有の timing / `stop_hook_active` ガードの後、共有 signal runtime の `finished` を呼び出す |

## ファイル構成

```text
home/dot_claude/hooks/                    # Claude 用の薄いアダプタ
  executable_pre-tool-use.sh             # → ~/.claude/hooks/pre-tool-use.sh
  executable_notification.sh             # → ~/.claude/hooks/notification.sh
  executable_stop.sh                     # → ~/.claude/hooks/stop.sh

home/dot_agents/hooks/                    # 共有コア
  bin/
    executable_check-preflight.sh        # → ~/.agents/hooks/bin/check-preflight.sh
    executable_agent-signal.sh           # → ~/.agents/hooks/bin/agent-signal.sh
    executable_agent-attention.sh        # → ~/.agents/hooks/bin/agent-attention.sh
    executable_agent-finished.sh         # → ~/.agents/hooks/bin/agent-finished.sh
    executable_agent-danger.sh           # → ~/.agents/hooks/bin/agent-danger.sh
  lib/
    executable_env_policy.sh             # → ~/.agents/hooks/lib/env_policy.sh
    executable_bash_policy.sh            # → ~/.agents/hooks/lib/bash_policy.sh
    executable_platform.sh               # → ~/.agents/hooks/lib/platform.sh
    executable_notify.sh                 # → ~/.agents/hooks/lib/notify.sh
```

`executable_` プレフィックスは chezmoi がデプロイ時に除去し、実行権限（`chmod +x`）を付与する。
詳細: [chezmoi.md — executable_ prefix の注意点](chezmoi.md)

実デプロイ後の共有 entrypoint は `.sh` 付きの名前で揃えている。既存の hook 配置との混在を避けるため、`~/.agents/hooks/bin/` 側もこの命名に統一する。

## 役割分担

Claude 側の hooks は入力の解釈と Claude 固有の制御だけを担当し、実際の判定や通知処理は `~/.agents/hooks/bin/` の共有コアに委譲する。

- `pre-tool-use.sh` は Claude の JSON payload を読み、`check-preflight.sh` に `tool_name` / `file_path` / `command` を渡し、危険な Bash deny のときだけ `agent-danger.sh` を鳴らす
- `notification.sh` は入力を破棄して `agent-attention.sh` を呼ぶ
- `stop.sh` は `stop_hook_active` と経過時間だけを Claude 側で扱い、完了 signal は `agent-finished.sh` に任せる

共有 Bash ポリシーは common-case の guardrail であり、完全な shell parser ではない。
危険なコマンドを実用上の頻出パターンで止めることを優先し、曖昧な入力は安全側に倒す。

## セキュリティフック (pre-tool-use.sh)

### ブロックルール（exit 2 → Claude へフィードバック）

| カテゴリ | パターン |
| --- | --- |
| 破壊的削除 | `rm -rf /`, `rm -rf ~`, `rm -rf /*`, `rm -rf .` |
| DB 破壊 | `DROP TABLE`, `DROP DATABASE`（大小文字不問） |
| 機密ファイル（Read/Edit/Write） | `.env` 系ファイル（キーワードアローリスト方式で判定） |
| 機密ファイル（Bash） | `cat`, `less`, `more`, `head`, `tail`, `grep`, `source`, `.` で `.env` 系を参照 |

### .env ファイルの判定ロジック

明示的な列挙では `.env.local`, `.env.stg`, `.env.prod.local` など多様な命名に対応できない。
**セグメントベースのキーワードアローリスト**で判定する:

```text
1. basename が ".env" で始まらない → スキップ（.envrc 等は対象外）
2. basename を "." で分割した各セグメントに安全キーワードが含まれる → ALLOW
3. それ以外 → BLOCK
```

安全キーワード: `example`, `template`, `sample`, `default`, `dist`, `schema`

| ファイル名 | 結果 |
| --- | --- |
| `.env` | BLOCK |
| `.env.local` | BLOCK |
| `.env.stg` | BLOCK |
| `.env.prod.local` | BLOCK |
| `.env.example` | ALLOW |
| `.env.template` | ALLOW |
| `.env.example.local` | ALLOW |
| `.envrc` | ALLOW（direnv 設定） |

### 警告ルール（exit 0 + stderr → verbose モードで表示）

| カテゴリ | パターン |
| --- | --- |
| sudo | `sudo` を含む |
| シェルへのパイプ | `curl \| bash`, `wget \| sh`, `curl \| sh` |

## 通知フック

### notification.sh

Claude が入力待ちや承認待ちになると即座に通知する。

### stop.sh

Claude がレスポンスを完了したとき、前回の stop から **10 秒以上**経過していれば通知する。
高速レスポンスでのノイズを抑制するため、`$TMPDIR/claude-last-stop-<session_id>` にタイムスタンプを記録して経過時間を計測する。

無限ループ防止: `stop_hook_active: true` のとき即座に exit 0。

## 通知ライブラリ (lib/)

### platform.sh

`$PLATFORM` 変数を export する（`macos` / `wsl` / `linux` / `unknown`）。

- macOS: `uname -s` == `Darwin`
- WSL: `$WSL_DISTRO_NAME` が設定されている、または Linux kernel の `osrelease` / `version` に `microsoft` / `WSL` が含まれる
- その他: `linux` または `unknown`

### notify.sh

`send_notification TITLE MESSAGE` に加えて `emit_agent_signal EVENT AGENT [MESSAGE]` を提供する。

| プラットフォーム | 既定チャネル | 主な使用コマンド |
| --- | --- | --- |
| macOS | `toast+sound` | `osascript`、sound-only fallback で `afplay` |
| Linux | `toast+sound` | `notify-send`、sound fallback で `play` |
| WSL | `sound` | `play` |
| その他 | `sound` | 利用可能コマンドがなければ 1 回だけ警告 |

共有 runtime はイベントを `attention` / `finished` / `danger` に正規化し、利用可能コマンドに応じて toast と sound を切り分ける。

## settings.json への統合

`run_apply-claude-settings.sh` の `DESIRED` ブロックに hooks 設定が含まれており、
適用時に既存のイベントキーと **per-event union マージ**される（他のイベントは保持）。

```json
  "hooks": {
    "PreToolUse": [
    {"matcher": "Bash|Read|Edit|Write|MultiEdit", "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-tool-use.sh"}]}
  ],
  "Notification": [
    {"matcher": "",                     "hooks": [{"type": "command", "command": "~/.claude/hooks/notification.sh"}]}
  ],
  "Stop": [
    {                                   "hooks": [{"type": "command", "command": "~/.claude/hooks/stop.sh"}]}
  ]
}
```

## テスト

```bash
bats tests/test_hooks.bats
```

テストは `home/dot_claude/hooks/` のアダプタと `home/dot_agents/hooks/` の共有コアを対象とする。
実運用では `chezmoi apply` か `make apply` で `~/.claude/hooks/` と `~/.agents/hooks/` に展開する。

## デプロイ手順

```bash
chezmoi apply          # スクリプトを ~/.claude/hooks/ に展開
bash home/dot_claude/run_apply-claude-settings.sh  # settings.json に hooks ブロックを書き込む
```

または:

```bash
make apply
```
