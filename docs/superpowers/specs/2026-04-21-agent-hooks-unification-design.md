# Agent Hooks Unification Design

Date: 2026-04-21

## Overview

Unify coding-agent hooks across Claude Code, Codex CLI, and Gemini CLI within
the dotfiles repository.

The goal is not identical hook behavior on every agent. The goal is to apply
the same shared policies where each agent supports them:

- Attention notifications
- Finished notifications
- Dangerous Bash command guardrails
- Sensitive `.env` access guardrails

This design covers only global hooks managed by dotfiles. Repo-local hook
configuration is out of scope.

## Design Goals

- Keep shared hook logic in one place
- Isolate agent-specific event schemas and return formats
- Reuse the existing `~/.agents/` shared-agent convention
- Use chezmoi for deployment and config generation
- Document capability gaps explicitly instead of hiding them

## Non-Goals

- Managing repo-local hooks such as `<repo>/.codex/hooks.json`
- Making all agents enforce the exact same protection level
- Building a logging or analytics pipeline
- Replacing existing project-level security policy

## Architecture

Shared hook logic lives under `~/.agents/hooks/`. Agent-specific directories
contain only thin adapters.

```text
~/.agents/hooks/
  lib/
    platform.sh
    notify.sh
    env_policy.sh
    bash_policy.sh
  bin/
    check-preflight.sh
    notify-attention.sh
    notify-finished.sh

~/.claude/hooks/
  pre-tool-use.sh
  notification.sh
  stop.sh

~/.codex/
  hooks.json
~/.codex/hooks/
  pre-tool-use.sh
  stop.sh

~/.gemini/hooks/
  pre-tool-use.sh
  stop.sh
  notification.sh
```

### Shared Core

The shared core is split by responsibility.

- `lib/`: reusable shell functions
- `bin/`: stable executable entrypoints used by adapters

This keeps agent adapters thin and allows tests to exercise common behavior
without duplicating agent-specific glue.

### Agent Adapters

Each adapter:

- reads hook JSON from stdin
- extracts only the fields needed by the shared core
- calls shared executables or functions
- maps the result into the agent's expected exit code and stdout/stderr format

Adapters must not implement policy logic directly unless required by a
tool-specific limitation.

## File Placement Rationale

### Why `home/dot_agents/hooks/`

`~/.agents/` is already the shared home for cross-agent instructions and
skills. Hooks belong in the same category: reusable agent infrastructure.

This makes `home/dot_agents/hooks/` the source of truth for:

- notification behavior
- `.env` sensitivity rules
- dangerous Bash detection

### Why not `home/.chezmoiscripts/`

`.chezmoiscripts/` is the right place for orchestration during `chezmoi apply`,
not for runtime hook implementations. Runtime hooks should be deployed as real
files to stable locations and be directly callable by agent settings.

### Role of `run_` Scripts

`run_` scripts remain responsible for writing or merging agent configuration:

- Claude Code: merge hook settings into `~/.claude/settings.json`
- Codex CLI: enable hook feature flags and manage `~/.codex/hooks.json`
- Gemini CLI: manage its global hook configuration file

The runtime hook bodies themselves are not stored in `.chezmoiscripts/`.

## Shared Policies

### Notification Policies

Two shared notification executables are always defined in the shared core:

- `notify-attention.sh`
- `notify-finished.sh`

This is true even if a given agent does not currently expose both event types.
An unsupported event simply remains unconnected in that agent's adapter/config.

`notify.sh` remains the platform-aware notification transport:

- macOS: `osascript`
- WSL/Linux: `notify-send` when available
- fallback: stderr notice

### Sensitive `.env` Policy

Sensitive env-file detection is centralized in one shared implementation.

Matching rules:

1. Only `.env` and `.env.*` are considered sensitive candidates
2. Filenames are split on `.`
3. If any segment matches a safe keyword, allow access
4. Otherwise treat the file as sensitive

Safe keywords:

- `example`
- `template`
- `sample`
- `default`
- `dist`
- `schema`

Examples:

| Filename | Result |
| --- | --- |
| `.env` | Block |
| `.env.local` | Block |
| `.env.prod.local` | Block |
| `.env.example` | Allow |
| `.env.example.local` | Allow |
| `.envrc` | Allow |

### Dangerous Bash Policy

Dangerous Bash detection is also centralized.

This policy is intentionally a guardrail for common interactive agent commands,
not a full shell parser or a complete security boundary. It should reliably
cover direct commands and common wrapper forms used by coding agents, while
avoiding obvious false positives on harmless text output.

In scope for blocking:

- direct command forms such as `rm -rf /`, `cat .env`, `psql -c "DROP TABLE"`
- common wrapper forms such as `sudo ...`, `env ...`, `command ...`,
  `bash -lc ...`, `sh -c ...`, `zsh -c ...`, `dash -c ...`
- common direct readers such as `cat`, `less`, `more`, `head`, `tail`, `grep`,
  `source`, `.`, and `sed`
- obvious SQL-client execution paths such as `psql -c ...` and
  `echo ... | psql`

Out of scope:

- arbitrary multi-step shell scripts
- exhaustive shell grammar coverage
- perfect detection of every quoting, expansion, separator, or heredoc form
- treating the hook as a substitute for sandboxing or permissions

Blocked patterns:

- `rm -rf /`
- `rm -rf ~`
- `rm -rf /*`
- `rm -rf .`
- `DROP TABLE`
- `DROP DATABASE`
- shell reads of sensitive `.env` files

Warn-only patterns:

- `sudo`
- `curl | bash`
- `curl | sh`
- `wget | sh`

The implementation should prefer stable behavior on typical agent-generated
commands over adversarial completeness. When there is a trade-off, avoid
turning this shared guardrail into a brittle mini shell interpreter.

## Agent Capability Mapping

The design intentionally distinguishes shared policy from agent capability.

### Claude Code Config

Claude has the strongest current coverage.

- `Notification` -> `notify-attention`
- `Stop` -> `notify-finished`
- `PreToolUse` on `Bash|Read|Edit|Write` -> shared preflight policy

Claude can enforce both:

- file-tool `.env` access blocking
- Bash-based `.env` access blocking

### Codex CLI Config

Codex uses global hooks through `~/.codex/hooks.json` with
`[features] codex_hooks = true`.

Planned mapping:

- `Stop` -> `notify-finished`
- `PreToolUse` on `Bash` -> shared preflight policy

Codex currently supports only partial `PreToolUse` interception and currently
emits `Bash` for that event. As a result:

- dangerous Bash blocking can be shared
- Bash-based `.env` access blocking can be shared
- direct `Read`/`Write`/`Edit` `.env` interception cannot yet match Claude

Codex attention notification is not part of the required shared baseline unless
Codex exposes a suitable global event later.

### Gemini CLI Config

Gemini should follow the same adapter pattern as Codex and Claude, but its
final event mapping depends on the exact global hook configuration supported by
the current official CLI.

Target mapping:

- attention notification when a matching global event exists
- finished notification on session/turn completion
- preflight policy where tool interception is available

Gemini adopts the shared core, but only wires the events that are officially
supported and stable.

## Configuration Strategy

### Claude Code

Keep using `run_apply-claude-settings.sh` to merge desired hook settings into
`~/.claude/settings.json`.

### Codex CLI

Extend Codex management to include:

- `[features] codex_hooks = true` in `~/.codex/config.toml`
- managed global `~/.codex/hooks.json`

`notify = ["~/.codex/hooks/notify.sh"]` should be evaluated during
implementation. If `Stop` hooks fully replace the need for that legacy notify
entry, remove it to avoid duplicated completion notifications.

### Gemini CLI

Manage Gemini's global hook configuration via a dedicated apply script, keeping
the same pattern used for Claude and Codex: preserve local/runtime-managed
settings, rewrite only the managed hook-related portion.

## Testing Strategy

Tests should run against deployed paths rather than raw chezmoi source files.

Coverage should include:

- shared `.env` filename classification
- shared dangerous Bash classification
- deployed Claude adapter behavior
- deployed Codex adapter behavior
- deployed Gemini adapter behavior where supported

Representative fixture JSON should be used for each agent because stdin payload
shape differs by tool.

## Risks and Constraints

- Agent hook support differs and may evolve independently
- Codex hook support is still experimental
- Bash interception is a guardrail for common cases, not a complete enforcement
  boundary
- Unsupported hook fields must fail safely and stay localized to adapters
- Duplicate completion notifications are possible if old and new Codex notify
  mechanisms are both enabled
- The shared Bash policy intentionally stops short of full shell parsing;
  residual bypasses for complex multi-step commands are acceptable within this
  design

## Implementation Direction

1. Move shared hook logic into `home/dot_agents/hooks/lib/` and
   `home/dot_agents/hooks/bin/`
2. Refactor Claude hook scripts into thin adapters
3. Add Codex global hook configuration and adapters
4. Add Gemini global hook configuration and adapters
5. Update docs for coding agents, Claude hooks, Codex, Gemini, and chezmoi
6. Add tests for shared policy and deployed adapters

## Open Design Decision Already Resolved

Attention notification is part of the shared core even if not every agent wires
it immediately. Shared availability and per-agent connection are separate
concerns, and the architecture reflects that explicitly.
