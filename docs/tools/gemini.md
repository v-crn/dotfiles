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
| `PreToolUse` | `~/.agents/hooks/bin/check-preflight.sh` を呼び出し、危険な Bash deny 時だけ `~/.agents/hooks/bin/agent-danger.sh` で警告音を鳴らす |
| `Notification` | `~/.agents/hooks/bin/agent-attention.sh` で注意喚起シグナルを送る |
| `Stop` | `~/.agents/hooks/bin/agent-finished.sh` で完了シグナルを送る |

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
通知チャネルの選択は Gemini 側ではなく共有 signal runtime が担当し、Linux/macOS では `toast+sound`、WSL では `sound` を既定にする。
WSL 判定は `WSL_DISTRO_NAME` だけに頼らず、kernel の `osrelease` / `version` に `microsoft` / `WSL` が含まれるケースも拾う。

## 展開

```bash
bats tests/test_gemini_settings.bats
markdownlint-cli2 docs/tools/gemini.md
```
