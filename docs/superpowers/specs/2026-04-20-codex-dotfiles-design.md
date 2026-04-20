# Codex Dotfiles Management Design

Date: 2026-04-20

## Overview

Manage `~/.codex/` files that are useful across environments via chezmoi, while
keeping environment-specific settings (project trust levels, auth) untouched.

## Files Under chezmoi Management

```text
home/dot_codex/
  AGENTS.md                    # codex global instructions
  run_apply-codex-config.sh    # config.toml dynamic generator
```

User-defined skills are added to `home/dot_codex/skills/` when created.
`~/.codex/skills/.system/` is managed by codex automatically and is excluded.

## AGENTS.md

A codex-specific `~/.codex/AGENTS.md` that incorporates `~/.agents/AGENTS.md`.

codex does not support `@path` include syntax (unlike Claude Code). Options:

- **chezmoi template**: use `.tmpl` to statically embed `~/.agents/AGENTS.md`
  content at `chezmoi apply` time
- **symlink**: if codex follows symlinks, link `~/.codex/AGENTS.md` →
  `~/.agents/AGENTS.md` (verify at implementation time)

Preferred: chezmoi template approach for reliability. Investigate symlink support
during implementation and switch if viable.

## config.toml Generation Script

### Managed Sections (overwritten on every apply)

| Section | Key settings |
| --- | --- |
| `[tui]` | `status_line`, `notifications`, `notification_condition`, `show_tooltips`, `animations`, `theme` |
| `model` | model name string |
| `model_reasoning_effort` | `"medium"` etc. |
| `approval_policy` | `"on-failure"` etc. |
| `sandbox_mode` | `"workspace-write"` etc. |
| `personality` | `"pragmatic"` etc. |
| `notify` | external notification command array |

**Notifications:** codex has two notification mechanisms:

- `[tui] notifications` + `notification_condition` — built-in desktop notifications
  via terminal (OSC 9 / BEL). Set `notification_condition = "always"` to notify
  even when the terminal is focused.
- `notify = [...]` — external command spawned after each agent turn. Reuse
  `~/.claude/hooks/lib/notify.sh` logic for platform-appropriate notifications
  (macOS: `osascript`, WSL/Linux: `notify-send`).

### Preserved Sections (never touched)

Everything not listed above is preserved automatically, including:

| Section | Reason |
| --- | --- |
| `[projects.*]` | Per-environment trust level — must be set locally |
| `[auth.*]` | Authentication credentials |
| `[notice.*]` | Per-installation state flags (dismissed warnings) — not preferences |
| Any future codex sections | Unknown sections are preserved by default |

### Script Logic

```sh
# 1. Backup
cp ~/.codex/config.toml ~/.codex/config.toml.bak

# 2. Remove managed sections from existing file (awk handles multi-line sections)
awk '
  /^\[?(tui|model|approval_policy|sandbox_mode|personality|notify)\]?/ { skip=1 }
  /^\[/ && !/^\[?(tui|model|approval_policy|sandbox_mode|personality|notify)\]?/ { skip=0 }
  !skip { print }
' ~/.codex/config.toml > /tmp/codex-config-base.toml

# 3. Append desired managed sections
cat /tmp/codex-config-base.toml DESIRED > ~/.codex/config.toml
```

The script follows the same pattern as `home/dot_claude/run_apply-claude-settings.sh`
(shell-only, no external tool dependencies beyond `awk`).

### Guard Conditions

- If `awk` is not found: warn and exit without modifying the file
- If `~/.codex/config.toml` does not exist: write DESIRED as-is (no backup needed)

## Out of Scope

- `~/.codex/auth.json` — authentication, never managed
- `~/.codex/memories/` — runtime state managed by codex
- `~/.codex/cache/`, `~/.codex/logs*`, `~/.codex/tmp/` — runtime artifacts
- `~/.codex/skills/.system/` — system skills managed by codex

## Related Docs

- `docs/tools/codex.md` — codex usage knowledge and configuration reference
  (to be created)
- `home/dot_claude/run_apply-claude-settings.sh` — reference implementation
  for the merge script pattern
