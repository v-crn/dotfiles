# Claude Code Hooks

Claude Code の hooks 機能を使い、セキュリティと通知の自動化を実装している。

## 概要

| Hook 種別 | トリガー | 動作 |
| --- | --- | --- |
| `PreToolUse` | ツール呼び出し前 | 危険なコマンドや機密ファイルアクセスをブロック |
| `Notification` | Claude が入力待ち・承認待ちになったとき | デスクトップ通知を送信 |
| `Stop` | Claude がレスポンスを完了したとき | 10 秒以上かかった場合に通知を送信 |

## ファイル構成

```text
home/dot_claude/hooks/                    # chezmoi ソース
  executable_pre-tool-use.sh             # → ~/.claude/hooks/pre-tool-use.sh
  executable_notification.sh             # → ~/.claude/hooks/notification.sh
  executable_stop.sh                     # → ~/.claude/hooks/stop.sh
  lib/
    executable_platform.sh               # → ~/.claude/hooks/lib/platform.sh
    executable_notify.sh                 # → ~/.claude/hooks/lib/notify.sh
```

`executable_` プレフィックスは chezmoi がデプロイ時に除去し、実行権限（`chmod +x`）を付与する。
詳細: [chezmoi.md — executable_ prefix の注意点](chezmoi.md)

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
- WSL: `$WSL_DISTRO_NAME` が設定されている
- その他: `linux` または `unknown`

### notify.sh

`send_notification TITLE MESSAGE` 関数を提供する。

| プラットフォーム | 使用コマンド | フォールバック |
| --- | --- | --- |
| macOS | `osascript` | — |
| WSL / Linux | `notify-send`（runtime で確認） | stderr に `[NOTICE]` |
| その他 | — | stderr に `[NOTICE]` |

`notify-send` の有無はインストール後の変更にも対応するため、毎回実行時に `command -v` で確認する。

## settings.json への統合

`run_apply-claude-settings.sh` の `DESIRED` ブロックに hooks 設定が含まれており、
適用時に既存のイベントキーと **per-event union マージ**される（他のイベントは保持）。

```json
"hooks": {
  "PreToolUse": [
    {"matcher": "Bash|Read|Edit|Write", "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-tool-use.sh"}]}
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

テストはデプロイ済みスクリプト (`~/.claude/hooks/`) を対象とするため、
事前に `chezmoi apply` か `make apply` を実行する必要がある。

## デプロイ手順

```bash
chezmoi apply          # スクリプトを ~/.claude/hooks/ に展開
bash home/dot_claude/run_apply-claude-settings.sh  # settings.json に hooks ブロックを書き込む
```

または:

```bash
make apply
```
