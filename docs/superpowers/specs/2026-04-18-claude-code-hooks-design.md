# Claude Code Generic Hooks Design

**Date:** 2026-04-18
**Branch:** dev
**Scope:** Security (A) + Notifications (B) in dotfiles, deployed via chezmoi

## Overview

Add general-purpose Claude Code hooks to the dotfiles repo. Hooks cover two concerns:

- **Security:** Block or warn on dangerous Bash commands and sensitive file access (PreToolUse)
- **Notifications:** Desktop notifications when Claude needs attention or finishes a response (Notification, Stop)

Logging (C) is out of scope — Claude Code already persists session history to `~/.claude/history.jsonl`.

---

## File Layout

### Dotfiles (source)

```text
home/dot_claude/
  hooks/
    lib/
      platform.sh       # Detect WSL / macOS / other
      notify.sh         # Send notification with per-platform command + fallback
    pre-tool-use.sh     # PreToolUse dispatcher (security checks)
    notification.sh     # Notification event handler
    stop.sh             # Stop event handler (completion notification)
```

### Deployed (via chezmoi)

```text
~/.claude/hooks/
  lib/platform.sh
  lib/notify.sh
  pre-tool-use.sh
  notification.sh
  stop.sh
```

All scripts are deployed with `chmod +x` via chezmoi.

---

## Architecture

### Dispatcher Pattern

`settings.json` references only the top-level scripts (`pre-tool-use.sh`, `notification.sh`, `stop.sh`). Each dispatcher sources `lib/` modules and implements its own logic. This keeps `settings.json` stable while allowing script logic to evolve independently.

### Platform Detection (`lib/platform.sh`)

Exports a `PLATFORM` variable:

```bash
# WSL2:  $WSL_DISTRO_NAME is set
# macOS: $(uname -s) == Darwin
# other: fallback
```

Sourced by any script that needs platform-aware behavior.

### Notification Library (`lib/notify.sh`)

Sources `platform.sh`, then exposes a `send_notification TITLE MESSAGE` function:

| Platform | Command | Availability check |
| --- | --- | --- |
| macOS | `osascript -e 'display notification ...'` | always available |
| WSL / Linux | `notify-send TITLE MESSAGE` | `command -v notify-send` at runtime |
| other | — | — |

Fallback for all platforms when the native command is unavailable: print `[NOTICE] TITLE: MESSAGE` to stderr so the message surfaces in Claude Code's verbose output (`Ctrl+O`).

Because `notify-send` availability is checked at runtime on every invocation, no reconfiguration is needed after installation.

---

## Security Hook (`pre-tool-use.sh`)

**Trigger:** `PreToolUse` on `Bash` and `Read|Edit|Write`

Reads JSON from stdin, extracts `tool_name` and `tool_input` with `jq`.

### Block rules (exit 2 → feedback to Claude)

| Category | Patterns |
| --- | --- |
| Destructive delete | `rm -rf /`, `rm -rf ~`, `rm -rf /*`, `rm -rf .` at repo root |
| DB destruction | `DROP TABLE`, `DROP DATABASE` (case-insensitive) |
| Sensitive file access | File path matches `\.env$` (for Read/Edit/Write tools) |
| Sensitive file via Bash | `cat .env`, `cat *.env`, `less .env`, etc. |

Note: `git reset --hard` and `git push --force` are already in the global deny list (`permissions.deny`), so they are not duplicated here.

### Warn rules (exit 0 + message to stderr → surfaced in verbose mode)

| Category | Patterns |
| --- | --- |
| sudo | command contains `sudo ` |
| Pipe to shell | `curl \| bash`, `wget \| sh`, `curl \| sh` patterns |

### Output format

Block: exit 2, reason written to stderr (Claude receives it as feedback).

Warn: exit 0, warning written to stderr (visible in `Ctrl+O` verbose mode, not sent to Claude).

---

## Notification Hooks

### `notification.sh` — Notification event

**Trigger:** `Notification` (Claude is waiting for input or permission)

Calls `send_notification "Claude Code" "Needs your attention"` via `lib/notify.sh`.

Always fires (no matcher restriction); the `Notification` event itself is selective enough.

### `stop.sh` — Stop event

**Trigger:** `Stop` (Claude finishes a response)

To avoid noise on fast responses, the script skips the notification when the session has been running for less than **10 seconds** (checked via `$EPOCHSECONDS` or `/proc/uptime` delta against a session start marker written to `$TMPDIR/claude-session-$session_id`).

Calls `send_notification "Claude Code" "Finished"` when the threshold is met.

Also guards against the infinite-loop pitfall: reads `stop_hook_active` from stdin JSON and exits 0 immediately if true.

---

## settings.json Integration

Hooks are added to the `DESIRED` block in `run_apply-claude-settings.sh`. The existing merge logic (`unique` union for arrays, overwrite for scalars) handles idempotent re-application.

```jsonc
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [{ "type": "command", "command": "~/.claude/hooks/pre-tool-use.sh" }]
    },
    {
      "matcher": "Read|Edit|Write",
      "hooks": [{ "type": "command", "command": "~/.claude/hooks/pre-tool-use.sh" }]
    }
  ],
  "Notification": [
    {
      "matcher": "",
      "hooks": [{ "type": "command", "command": "~/.claude/hooks/notification.sh" }]
    }
  ],
  "Stop": [
    {
      "hooks": [{ "type": "command", "command": "~/.claude/hooks/stop.sh" }]
    }
  ]
}
```

The merge strategy for `hooks` in `run_apply-claude-settings.sh`: **overwrite** (replace the entire `hooks` object from `DESIRED`). This differs from the array-union approach used for `permissions.allow/deny`, because hook order and deduplication are managed at the script level, not via JSON merging.

---

## Constraints and Non-Goals

- No logging hooks — `~/.claude/history.jsonl` already covers this.
- No Windows / PowerShell notification — WSL is always running in this environment.
- Hook scripts are POSIX sh compatible (no bash-isms beyond `[[ ]]`) for portability.
- `jq` is a hard dependency (already assumed in `run_apply-claude-settings.sh`).
- Scripts must be idempotent and exit quickly; no blocking I/O.

---

## Testing Plan

1. Run `chezmoi apply` and verify scripts land in `~/.claude/hooks/` with execute permission.
2. Run `run_apply-claude-settings.sh` and verify `~/.claude/settings.json` contains the hooks block.
3. Verify in `/hooks` menu that all three hooks appear.
4. Security — block: ask Claude to run `cat .env`; confirm block message appears.
5. Security — warn: ask Claude to run `sudo ls`; confirm verbose output shows warning.
6. Notification: start a long task, switch focus; confirm notification fires.
7. Stop: complete a short task (<10 s); confirm no notification. Complete a long task; confirm notification fires.
8. `notify-send` absent: confirm `[NOTICE]` fallback appears in stderr/verbose output.
