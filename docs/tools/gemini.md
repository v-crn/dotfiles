# Gemini CLI Hooks

Gemini CLI のグローバル hooks と設定生成の管理内容をまとめる。

## 管理対象

```text
home/dot_gemini/
  GEMINI.md.tmpl
  hooks/
    executable_pre-tool-use.sh
    executable_notification.sh
    executable_stop.sh
  run_apply-gemini-settings.sh
```

## hooks の役割

| 種別 | 役割 |
| --- | --- |
| `PreToolUse` | `~/.agents/hooks/bin/check-preflight.sh` を呼び出して危険な Bash / `.env` アクセスを止める |
| `Notification` | `~/.agents/hooks/bin/notify-attention.sh` で注意喚起を送る |
| `Stop` | `~/.agents/hooks/bin/notify-finished.sh` で完了通知を送る |

## 設定生成

`home/dot_gemini/run_apply-gemini-settings.sh` は `~/.gemini/settings.json` のうち hooks 部分だけを管理する。
既存の top-level 設定や、managed 以外の hooks はできるだけ残す。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Read|Edit|MultiEdit|Write",
        "hooks": [{ "type": "command", "command": "~/.gemini/hooks/pre-tool-use.sh" }]
      }
    ],
    "Notification": [
      {
        "hooks": [{ "type": "command", "command": "~/.gemini/hooks/notification.sh" }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "type": "command", "command": "~/.gemini/hooks/stop.sh" }]
      }
    ]
  }
}
```

共有 Bash policy は common-case の guardrail であり、完全な shell parser ではない。
`PreToolUse` の matcher は `MultiEdit` を含める。

## 展開

```bash
bats tests/test_gemini_settings.bats
markdownlint-cli2 docs/tools/gemini.md
```
