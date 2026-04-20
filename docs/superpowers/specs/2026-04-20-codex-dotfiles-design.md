# Codex Dotfiles Management Design

Date: 2026-04-20

## Overview

Manage `~/.codex/` files that are useful across environments via chezmoi, while
keeping environment-specific settings (project trust levels, auth) untouched.

## Files Under chezmoi Management

```text
home/dot_agents/hooks/lib/        ← shared notification infrastructure (moved here)
  executable_notify.sh
  executable_platform.sh

home/dot_claude/hooks/lib/
  executable_notify.sh            ← shim that sources ~/.agents/hooks/lib/notify.sh

home/dot_codex/
  AGENTS.md                       ← codex global instructions
  hooks/
    executable_notify.sh          ← sources ~/.agents/hooks/lib/notify.sh
  run_apply-codex-config.sh       ← config.toml dynamic generator
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

Also note: `AGENTS.override.md` (not managed by chezmoi) can be placed in a
project directory for personal instruction overrides without committing to git.

## Shared Notification Infrastructure

Notification logic is shared between Claude Code and Codex via `~/.agents/hooks/lib/`:

- `~/.agents/hooks/lib/platform.sh` — platform detection (macOS / WSL / Linux)
- `~/.agents/hooks/lib/notify.sh` — `send_notification TITLE MESSAGE` using
  `osascript` on macOS, `notify-send` on WSL/Linux

`~/.claude/hooks/lib/notify.sh` becomes a shim sourcing the shared library.
`~/.codex/hooks/notify.sh` sources the same library and is referenced by `notify`
in `config.toml`.

## config.toml Generation Script

### Design Principles

Only set values that differ from their defaults. This keeps the config minimal
and avoids confusing "no-op" settings.

| Setting | Default | Why we set it |
| --- | --- | --- |
| `sandbox_mode` | `read-only` | Dev needs `workspace-write` |
| `approval_policy` | `on-request` | Explicit intent; note `on-failure` is deprecated |
| `model` | none | Pin a specific model to avoid surprises |
| `model_reasoning_effort` | none | Tune cost vs. quality |
| `personality` | none | Personal preference |
| `notify` | none | Enable post-turn notifications via shared script |
| `[tui] status_line` | minimal | Match Claude Code's status line |
| `[tui] notifications` | true | Already on by default; set `notification_condition` |
| `[tui] notification_condition` | `unfocused` | Change to `always` for consistent alerts |
| `[features] memories` | false | Enable cross-session memory |
| `[memories]` | disabled | Configure memory pipeline |
| `[profiles.*]` | none | Named presets for conservative / development use |

Not set (already correct defaults):

- `web_search` — defaults to `"cached"` (search enabled); only override to
  `"live"` or `"disabled"` if needed

### Managed Sections (overwritten on every apply)

`tui`, `model`, `model_reasoning_effort`, `approval_policy`, `sandbox_mode`,
`personality`, `notify`, `features`, `memories`, `profiles`

### Preserved Sections (never touched)

Everything not in the managed list is preserved automatically, including:

| Section | Reason |
| --- | --- |
| `[projects.*]` | Per-environment trust level — must be set locally |
| `[auth.*]` | Authentication credentials |
| `[notice.*]` | Per-installation dismissed-warning state, not a preference |
| Any future codex sections | Unknown sections are preserved by default |

### Script Logic

```sh
# 1. Backup
cp ~/.codex/config.toml ~/.codex/config.toml.bak

# 2. Strip managed sections from existing file
MANAGED='tui|model|model_reasoning_effort|approval_policy|sandbox_mode|personality|notify|features|memories|profiles'
awk -v pat="^\\[($MANAGED)(\\.|\\])" '
  $0 ~ pat         { skip=1 }
  /^\[/ && !($0 ~ pat) { skip=0 }
  !skip            { print }
' ~/.codex/config.toml > /tmp/codex-config-base.toml

# 3. Append desired managed sections
cat /tmp/codex-config-base.toml - <<'DESIRED' > ~/.codex/config.toml
... (desired TOML here) ...
DESIRED
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
