# Agent Hooks Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify global hook behavior across Claude Code, Codex CLI, and Gemini CLI by moving shared hook policy into `~/.agents/hooks/`, keeping per-agent adapters thin, and updating configuration, docs, and tests accordingly.

**Architecture:** Shared shell logic lives under `home/dot_agents/hooks/lib/` and stable executables live under `home/dot_agents/hooks/bin/`. Claude, Codex, and Gemini keep only adapter scripts plus per-tool config generators, so event-schema differences stay local while `.env` and dangerous Bash policy stay centralized.

**Tech Stack:** chezmoi, POSIX shell/Bash, jq, awk, bats, markdownlint-cli2

---

## File Structure

- `home/dot_agents/hooks/lib/executable_platform.sh`
  - Keep existing platform detection helper as shared dependency.
- `home/dot_agents/hooks/lib/executable_notify.sh`
  - Keep existing cross-platform notification transport.
- `home/dot_agents/hooks/lib/executable_env_policy.sh`
  - New shared `.env` sensitivity classifier.
- `home/dot_agents/hooks/lib/executable_bash_policy.sh`
  - New shared dangerous Bash classifier.
- `home/dot_agents/hooks/bin/executable_check-preflight.sh`
  - New stable shared CLI for preflight policy checks.
- `home/dot_agents/hooks/bin/executable_notify-attention.sh`
  - New stable shared CLI for attention notifications.
- `home/dot_agents/hooks/bin/executable_notify-finished.sh`
  - New stable shared CLI for completion notifications.
- `home/dot_claude/hooks/executable_pre-tool-use.sh`
  - Refactor into adapter that calls shared preflight logic.
- `home/dot_claude/hooks/executable_notification.sh`
  - Refactor into adapter that calls shared attention notification.
- `home/dot_claude/hooks/executable_stop.sh`
  - Refactor into adapter that calls shared finished notification.
- `home/dot_codex/hooks/executable_pre-tool-use.sh`
  - New Codex `PreToolUse` adapter.
- `home/dot_codex/hooks/executable_stop.sh`
  - New Codex `Stop` adapter.
- `home/dot_codex/private_hooks.json.tmpl`
  - New managed global Codex hooks file.
- `home/dot_codex/run_apply-codex-config.sh`
  - Enable `features.codex_hooks` and remove legacy `notify` if `Stop` replaces it.
- `home/dot_gemini/hooks/executable_pre-tool-use.sh`
  - New Gemini preflight adapter.
- `home/dot_gemini/hooks/executable_notification.sh`
  - New Gemini attention-notification adapter if supported by current official event model.
- `home/dot_gemini/hooks/executable_stop.sh`
  - New Gemini finished-notification adapter.
- `home/dot_gemini/run_apply-gemini-settings.sh`
  - New apply script for Gemini global hook config.
- `tests/test_hooks.bats`
  - Expand to cover shared core and Claude adapter behavior.
- `tests/test_codex_config.bats`
  - New tests for Codex config merge and `hooks.json` deployment expectations.
- `tests/test_gemini_settings.bats`
  - New tests for Gemini hook config generation.
- `docs/tools/coding_agents.md`
  - Document shared hook layout under `~/.agents/hooks/`.
- `docs/tools/claude_code_hooks.md`
  - Update to describe adapters and shared core.
- `docs/tools/codex.md`
  - Document Codex global hooks, `features.codex_hooks`, and `~/.codex/hooks.json`.
- `docs/tools/gemini.md`
  - New repo doc describing Gemini global hooks configuration and managed files.
- `docs/tools/chezmoi.md`
  - Clarify why runtime hooks live in `home/dot_agents/hooks/` instead of `.chezmoiscripts/`.

## Scope Guardrail

The shared Bash policy in Task 1 is a common-case guardrail, not a full shell
parser.

Required coverage:

- direct commands such as `rm -rf /`, `cat .env`, and `psql -c "DROP TABLE"`
- common wrappers such as `sudo`, `env`, `command`, `bash -lc`, `sh -c`,
  `zsh -c`, and `dash -c`
- common direct readers such as `cat`, `less`, `more`, `head`, `tail`, `grep`,
  `source`, `.`, and `sed`
- obvious SQL execution paths such as `psql -c ...` and `echo ... | psql`

Not required for Task 1:

- arbitrary multi-step shell programs
- exhaustive quoting and expansion handling
- perfect detection of every shell grammar edge case
- treating the hook as a security boundary stronger than sandboxing

If later review feedback asks for full shell-parser behavior, treat that as out
of scope unless the plan is explicitly expanded.

### Task 1: Add Shared Hook Core

**Files:**

- Create: `home/dot_agents/hooks/lib/executable_env_policy.sh`
- Create: `home/dot_agents/hooks/lib/executable_bash_policy.sh`
- Create: `home/dot_agents/hooks/bin/executable_check-preflight.sh`
- Create: `home/dot_agents/hooks/bin/executable_notify-attention.sh`
- Create: `home/dot_agents/hooks/bin/executable_notify-finished.sh`
- Modify: `tests/test_hooks.bats`

- [ ] **Step 1: Write the failing tests for the shared core**

Add these tests near the top of `tests/test_hooks.bats` after the existing
`notify.sh` section:

```bash
ENV_POLICY_SH="$HOME/.agents/hooks/lib/env_policy.sh"
BASH_POLICY_SH="$HOME/.agents/hooks/lib/bash_policy.sh"
CHECK_PREFLIGHT_SH="$HOME/.agents/hooks/bin/check-preflight.sh"
NOTIFY_ATTENTION_SH="$HOME/.agents/hooks/bin/notify-attention.sh"
NOTIFY_FINISHED_SH="$HOME/.agents/hooks/bin/notify-finished.sh"

@test "env_policy.sh: blocks .env.local" {
    run bash -c ". '$ENV_POLICY_SH'; is_sensitive_env_file '.env.local'"
    [ "$status" -eq 0 ]
}

@test "env_policy.sh: allows .env.example" {
    run bash -c ". '$ENV_POLICY_SH'; is_sensitive_env_file '.env.example'"
    [ "$status" -eq 1 ]
}

@test "bash_policy.sh: blocks DROP DATABASE" {
    run bash -c ". '$BASH_POLICY_SH'; check_dangerous_bash_command 'psql -c \"DROP DATABASE mydb;\"'"
    [ "$status" -eq 2 ]
}

@test "check-preflight.sh: blocks sensitive Read path" {
    run bash "$CHECK_PREFLIGHT_SH" Read /workspace/project/.env ""
    [ "$status" -eq 2 ]
}

@test "check-preflight.sh: allows .env.example Read path" {
    run bash "$CHECK_PREFLIGHT_SH" Read /workspace/project/.env.example ""
    [ "$status" -eq 0 ]
}

@test "notify-attention.sh: exists and is executable" {
    [ -x "$NOTIFY_ATTENTION_SH" ]
}

@test "notify-finished.sh: exists and is executable" {
    [ -x "$NOTIFY_FINISHED_SH" ]
}
```

- [ ] **Step 2: Run the targeted test file and verify it fails**

Run:

```bash
bats tests/test_hooks.bats
```

Expected:

```text
not ok 1 env_policy.sh: blocks .env.local
not ok 2 bash_policy.sh: blocks DROP DATABASE
not ok 3 check-preflight.sh: blocks sensitive Read path
```

- [ ] **Step 3: Add the shared `.env` policy library**

Create `home/dot_agents/hooks/lib/executable_env_policy.sh` with this content:

```bash
#!/bin/bash
# Shared .env filename policy.
# Return 0 when the given path should be treated as sensitive.

is_sensitive_env_file() {
    local base stripped old_ifs segment
    base="$(basename "$1")"
    case "$base" in
        .env|.env.*) ;;
        *) return 1 ;;
    esac

    stripped="${base#.}"
    old_ifs="$IFS"
    IFS='.'
    # shellcheck disable=SC2086
    set -- $stripped
    IFS="$old_ifs"

    for segment; do
        case "$segment" in
            example|template|sample|default|dist|schema)
                return 1
                ;;
        esac
    done

    return 0
}
```

- [ ] **Step 4: Add the shared Bash policy library**

Create `home/dot_agents/hooks/lib/executable_bash_policy.sh` with this content:

```bash
#!/bin/bash
# Shared Bash preflight checks.
# Return 2 to block, 0 to allow. Warnings go to stderr.

# shellcheck disable=SC1090,SC1091
. ~/.agents/hooks/lib/env_policy.sh

check_dangerous_bash_command() {
    local command upper env_ref
    command="$1"

    case "$command" in
        *"rm -rf ~"*|*"rm -rf /*"*|*"rm -rf ."*)
            printf 'Blocked: destructive rm detected. Command: %s\n' "$command" >&2
            return 2
            ;;
    esac

    if printf '%s' "$command" | grep -qE 'rm[[:space:]]+-rf[[:space:]]+/([[:space:];]|$)'; then
        printf 'Blocked: destructive rm detected. Command: %s\n' "$command" >&2
        return 2
    fi

    upper="$(printf '%s' "$command" | tr '[:lower:]' '[:upper:]')"
    case "$upper" in
        *"DROP TABLE"*|*"DROP DATABASE"*)
            printf 'Blocked: destructive SQL command detected.\n' >&2
            return 2
            ;;
    esac

    case "$command" in
        cat\ *|less\ *|more\ *|head\ *|tail\ *|grep\ *|source\ *|.\ *)
            env_ref="$(printf '%s' "$command" | grep -oE '\.env[a-zA-Z0-9._-]*' | head -1)"
            if [ -n "$env_ref" ] && is_sensitive_env_file "$env_ref"; then
                printf 'Blocked: reading sensitive env file via shell: %s\n' "$env_ref" >&2
                return 2
            fi
            ;;
    esac

    case "$command" in
        *"sudo "*)
            printf 'Warning: sudo usage detected. Ensure this is intentional: %s\n' "$command" >&2
            ;;
    esac

    case "$command" in
        *"| bash"*|*"| sh"*|*"|bash"*|*"|sh"*)
            printf 'Warning: pipe-to-shell detected (supply chain risk): %s\n' "$command" >&2
            ;;
    esac

    return 0
}
```

- [ ] **Step 5: Add the stable shared CLI entrypoints**

Create `home/dot_agents/hooks/bin/executable_check-preflight.sh`:

```bash
#!/bin/bash
# Shared preflight CLI.
# Usage: check-preflight.sh TOOL_NAME FILE_PATH COMMAND

tool_name="${1:-}"
file_path="${2:-}"
command="${3:-}"

# shellcheck disable=SC1090,SC1091
. ~/.agents/hooks/lib/env_policy.sh
# shellcheck disable=SC1090,SC1091
. ~/.agents/hooks/lib/bash_policy.sh

case "$tool_name" in
    Read|Edit|MultiEdit|Write)
        if [ -n "$file_path" ] && is_sensitive_env_file "$file_path"; then
            printf 'Blocked: %s is a sensitive .env file. Use .env.example (or similar) for templates.\n' \
                "$(basename "$file_path")" >&2
            exit 2
        fi
        ;;
    Bash)
        check_dangerous_bash_command "$command"
        exit $?
        ;;
esac

exit 0
```

Create `home/dot_agents/hooks/bin/executable_notify-attention.sh`:

```bash
#!/bin/bash
# Shared attention notification hook entrypoint.
# shellcheck disable=SC1090,SC1091
. ~/.agents/hooks/lib/notify.sh

send_notification "${1:-Agent}" "${2:-Needs your attention}"
```

Create `home/dot_agents/hooks/bin/executable_notify-finished.sh`:

```bash
#!/bin/bash
# Shared completion notification hook entrypoint.
# shellcheck disable=SC1090,SC1091
. ~/.agents/hooks/lib/notify.sh

send_notification "${1:-Agent}" "${2:-Finished}"
```

- [ ] **Step 6: Run the shared hook tests and verify they pass**

Run:

```bash
bats tests/test_hooks.bats
```

Expected:

```text
ok 1 platform.sh: exists and is executable
ok 2 platform.sh: detects macOS when uname returns Darwin
...
ok N check-preflight.sh: allows .env.example Read path
```

- [ ] **Step 7: Commit the shared core**

Run:

```bash
git add home/dot_agents/hooks/lib home/dot_agents/hooks/bin tests/test_hooks.bats
git commit -m "refactor: add shared agent hook core"
```

Expected:

```text
[dev ...] refactor: add shared agent hook core
```

- [ ] **Step 8: Verify Task 1 stays within common-case scope**

Manually confirm that `home/dot_agents/hooks/lib/executable_bash_policy.sh`
still targets common interactive agent commands and wrappers, rather than
trying to parse arbitrary shell scripts. If new review feedback asks for
full-shell coverage, record it as out of scope for Task 1 unless the plan is
explicitly expanded.

### Task 2: Refactor Claude Hooks Into Thin Adapters

**Files:**

- Modify: `home/dot_claude/hooks/executable_pre-tool-use.sh`
- Modify: `home/dot_claude/hooks/executable_notification.sh`
- Modify: `home/dot_claude/hooks/executable_stop.sh`
- Modify: `docs/tools/claude_code_hooks.md`
- Test: `tests/test_hooks.bats`

- [ ] **Step 1: Extend tests to assert Claude adapters delegate to the shared core**

Add these tests to `tests/test_hooks.bats` below the current Claude `pre-tool-use`
tests:

```bash
CLAUDE_NOTIFICATION_SH="$HOME/.claude/hooks/notification.sh"
CLAUDE_STOP_SH="$HOME/.claude/hooks/stop.sh"

@test "claude notification adapter: exists and is executable" {
    [ -x "$CLAUDE_NOTIFICATION_SH" ]
}

@test "claude stop adapter: exists and is executable" {
    [ -x "$CLAUDE_STOP_SH" ]
}

@test "claude pre-tool-use adapter: blocks MultiEdit of .env" {
    run run_hook '{"tool_name":"MultiEdit","tool_input":{"file_path":"/project/.env"}}'
    [ "$status" -eq 2 ]
}
```

- [ ] **Step 2: Run Claude hook tests to verify the new adapter expectation fails**

Run:

```bash
bats tests/test_hooks.bats
```

Expected:

```text
not ok 1 claude pre-tool-use adapter: blocks MultiEdit of .env
```

- [ ] **Step 3: Replace Claude pre-tool-use logic with a shared-core adapter**

Overwrite `home/dot_claude/hooks/executable_pre-tool-use.sh` with:

```bash
#!/bin/bash
# Claude Code PreToolUse adapter.

input="$(cat)"
tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"

exec ~/.agents/hooks/bin/check-preflight.sh "$tool_name" "$file_path" "$command"
```

- [ ] **Step 4: Replace Claude notification and stop logic with shared adapters**

Overwrite `home/dot_claude/hooks/executable_notification.sh` with:

```bash
#!/bin/bash
# Claude Code Notification adapter.

exec ~/.agents/hooks/bin/notify-attention.sh "Claude Code" "Needs your attention"
```

Overwrite `home/dot_claude/hooks/executable_stop.sh` with:

```bash
#!/bin/bash
# Claude Code Stop adapter.

input="$(cat)"

if [ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ]; then
    exit 0
fi

session_id="$(printf '%s' "$input" | jq -r '.session_id // empty')"
if [ -z "$session_id" ]; then
    exit 0
fi

marker_file="${TMPDIR:-/tmp}/claude-last-stop-${session_id}"
now="$(date +%s)"

if [ ! -f "$marker_file" ]; then
    printf '%s\n' "$now" > "$marker_file"
    exit 0
fi

last_stop="$(cat "$marker_file")"
elapsed=$(( now - last_stop ))
printf '%s\n' "$now" > "$marker_file"

if [ "$elapsed" -ge 10 ]; then
    exec ~/.agents/hooks/bin/notify-finished.sh "Claude Code" "Finished"
fi

exit 0
```

- [ ] **Step 5: Update the Claude hooks doc to describe the adapter layout**

In `docs/tools/claude_code_hooks.md`, replace the file layout block with:

````md
```text
home/dot_agents/hooks/                    # shared core used by multiple agents
  bin/
    executable_check-preflight.sh
    executable_notify-attention.sh
    executable_notify-finished.sh
  lib/
    executable_platform.sh
    executable_notify.sh
    executable_env_policy.sh
    executable_bash_policy.sh

home/dot_claude/hooks/                    # Claude-specific adapters
  executable_pre-tool-use.sh             # -> ~/.claude/hooks/pre-tool-use.sh
  executable_notification.sh             # -> ~/.claude/hooks/notification.sh
  executable_stop.sh                     # -> ~/.claude/hooks/stop.sh
```
````

Also replace the dispatcher description with this paragraph:

```md
Claude hook files are now thin adapters. They parse Claude's hook payload,
delegate to `~/.agents/hooks/bin/`, and keep Claude-specific event behavior
such as `stop_hook_active` handling local to the adapter.
```

- [ ] **Step 6: Run the hook tests and markdown lint**

Run:

```bash
bats tests/test_hooks.bats
markdownlint-cli2 docs/tools/claude_code_hooks.md
```

Expected:

```text
ok 1 platform.sh: exists and is executable
...
Summary: 0 error(s)
```

- [ ] **Step 7: Commit the Claude adapter refactor**

Run:

```bash
git add home/dot_claude/hooks docs/tools/claude_code_hooks.md tests/test_hooks.bats
git commit -m "refactor: move claude hooks to shared adapters"
```

Expected:

```text
[dev ...] refactor: move claude hooks to shared adapters
```

### Task 3: Add Codex Global Hooks and Config Support

**Files:**

- Create: `home/dot_codex/hooks/executable_pre-tool-use.sh`
- Create: `home/dot_codex/hooks/executable_stop.sh`
- Create: `home/dot_codex/private_hooks.json.tmpl`
- Modify: `home/dot_codex/run_apply-codex-config.sh`
- Create: `tests/test_codex_config.bats`
- Modify: `docs/tools/codex.md`

- [ ] **Step 1: Write failing tests for Codex hook config**

Create `tests/test_codex_config.bats` with:

```bash
#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI_ROOT="$(tr -d '[:space:]' < "$REPO_ROOT/.chezmoiroot")"
SCRIPT="$REPO_ROOT/$CHEZMOI_ROOT/dot_codex/run_apply-codex-config.sh"

setup() {
    TEST_HOME="$(mktemp -d)"
    mkdir -p "$TEST_HOME/.codex"
    export HOME="$TEST_HOME"
}

teardown() {
    rm -rf "$TEST_HOME"
}

@test "new install: enables codex_hooks feature" {
    "$SCRIPT"
    run grep -q 'codex_hooks = true' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]
}

@test "new install: does not keep legacy notify key" {
    "$SCRIPT"
    run grep -q '^notify =' "$HOME/.codex/config.toml"
    [ "$status" -eq 1 ]
}
```

- [ ] **Step 2: Run the new Codex config tests and verify they fail**

Run:

```bash
bats tests/test_codex_config.bats
```

Expected:

```text
not ok 1 new install: enables codex_hooks feature
not ok 2 new install: does not keep legacy notify key
```

- [ ] **Step 3: Add Codex adapters and the managed hooks file**

Create `home/dot_codex/hooks/executable_pre-tool-use.sh`:

```bash
#!/bin/bash
# Codex PreToolUse adapter.

input="$(cat)"
tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"

if ~/.agents/hooks/bin/check-preflight.sh "$tool_name" "" "$command"; then
    exit 0
fi

status=$?
if [ "$status" -eq 2 ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked by shared preflight policy."}}\n'
    exit 0
fi

exit "$status"
```

Create `home/dot_codex/hooks/executable_stop.sh`:

```bash
#!/bin/bash
# Codex Stop adapter.

input="$(cat)"

if [ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = "true" ]; then
    printf '{"continue":true}\n'
    exit 0
fi

exec ~/.agents/hooks/bin/notify-finished.sh "Codex" "Finished"
```

Create `home/dot_codex/private_hooks.json.tmpl`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.codex/hooks/pre-tool-use.sh",
            "statusMessage": "Checking Bash command"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.codex/hooks/stop.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 4: Enable Codex hooks in the config generator**

In `home/dot_codex/run_apply-codex-config.sh`, replace the `DESIRED` block with:

```toml
model = "o4-mini"
model_reasoning_effort = "medium"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
personality = "Be concise and precise. Prefer minimal, focused changes. Follow existing code conventions."

[tui]
status_line = [
    "model-with-reasoning",
    "current-dir",
    "git-branch",
    "context-used",
    "context-window-size",
]
notifications = true
notification_condition = "always"

[features]
memories = true
codex_hooks = true

[profiles.conservative]
approval_policy = "on-request"
sandbox_mode = "read-only"

[profiles.development]
approval_policy = "on-request"
sandbox_mode = "workspace-write"
```

Also update the managed key metadata comments and `MANAGED_KEYS` line to remove
`notify`:

```bash
#   model, model_reasoning_effort, approval_policy, sandbox_mode, personality
MANAGED_KEYS='model|model_reasoning_effort|approval_policy|sandbox_mode|personality'
```

- [ ] **Step 5: Document Codex global hooks**

In `docs/tools/codex.md`, update the top comparison table row to:

```md
| フック種別 | `hooks.json` による `PreToolUse` / `Stop` など + 実験的 `codex_hooks` | pre/post tool-use など多彩 |
```

Add this new section after the current "通知フック" section:

```md
## Global Hooks

Codex CLI は `~/.codex/hooks.json` からグローバル hooks を読み込む。dotfiles では
`home/dot_codex/private_hooks.json.tmpl` を `~/.codex/hooks.json` にデプロイし、
`~/.codex/hooks/pre-tool-use.sh` と `~/.codex/hooks/stop.sh` の thin adapter から
`~/.agents/hooks/bin/` の shared core を呼び出す。

`PreToolUse` は現状 `Bash` のみが実用対象で、Claude の `Read|Edit|Write` と同じ
粒度の防御はまだ行えない。
```

- [ ] **Step 6: Run Codex tests and lint the doc**

Run:

```bash
bats tests/test_codex_config.bats
markdownlint-cli2 docs/tools/codex.md
```

Expected:

```text
ok 1 new install: enables codex_hooks feature
ok 2 new install: does not keep legacy notify key
Summary: 0 error(s)
```

- [ ] **Step 7: Commit the Codex hook integration**

Run:

```bash
git add home/dot_codex tests/test_codex_config.bats docs/tools/codex.md
git commit -m "feat: add codex global hook adapters"
```

Expected:

```text
[dev ...] feat: add codex global hook adapters
```

### Task 4: Add Gemini Global Hook Management

**Files:**

- Create: `home/dot_gemini/hooks/executable_pre-tool-use.sh`
- Create: `home/dot_gemini/hooks/executable_notification.sh`
- Create: `home/dot_gemini/hooks/executable_stop.sh`
- Create: `home/dot_gemini/run_apply-gemini-settings.sh`
- Create: `tests/test_gemini_settings.bats`
- Create: `docs/tools/gemini.md`

- [ ] **Step 1: Write failing tests for the Gemini settings generator**

Create `tests/test_gemini_settings.bats` with:

```bash
#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI_ROOT="$(tr -d '[:space:]' < "$REPO_ROOT/.chezmoiroot")"
SCRIPT="$REPO_ROOT/$CHEZMOI_ROOT/dot_gemini/run_apply-gemini-settings.sh"

setup() {
    TEST_HOME="$(mktemp -d)"
    mkdir -p "$TEST_HOME/.gemini"
    export HOME="$TEST_HOME"
}

teardown() {
    rm -rf "$TEST_HOME"
}

@test "script exists" {
    [ -x "$SCRIPT" ]
}

@test "new install: creates Gemini settings.json" {
    "$SCRIPT"
    [ -f "$HOME/.gemini/settings.json" ]
}

@test "new install: config points to deployed hook adapters" {
    "$SCRIPT"
    run jq -r '.hooks.PreToolUse[0].hooks[0].command' "$HOME/.gemini/settings.json"
    [ "$output" = "~/.gemini/hooks/pre-tool-use.sh" ]
}
```

- [ ] **Step 2: Run the Gemini tests and verify they fail**

Run:

```bash
bats tests/test_gemini_settings.bats
```

Expected:

```text
not ok 1 script exists
not ok 2 new install: creates Gemini settings.json
```

- [ ] **Step 3: Add Gemini hook adapters**

Create `home/dot_gemini/hooks/executable_pre-tool-use.sh`:

```bash
#!/bin/bash
# Gemini PreToolUse adapter.

input="$(cat)"
tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"
command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"

exec ~/.agents/hooks/bin/check-preflight.sh "$tool_name" "$file_path" "$command"
```

Create `home/dot_gemini/hooks/executable_notification.sh`:

```bash
#!/bin/bash
# Gemini attention notification adapter.

exec ~/.agents/hooks/bin/notify-attention.sh "Gemini" "Needs your attention"
```

Create `home/dot_gemini/hooks/executable_stop.sh`:

```bash
#!/bin/bash
# Gemini completion notification adapter.

exec ~/.agents/hooks/bin/notify-finished.sh "Gemini" "Finished"
```

- [ ] **Step 4: Add the Gemini settings apply script**

Create `home/dot_gemini/run_apply-gemini-settings.sh` with:

```bash
#!/bin/sh
# Apply Gemini settings, rewriting only the managed hook block.

DESIRED=$(cat <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Read|Edit|MultiEdit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "~/.gemini/hooks/pre-tool-use.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.gemini/hooks/notification.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.gemini/hooks/stop.sh"
          }
        ]
      }
    ]
  }
}
EOF
)

TARGET="$HOME/.gemini/settings.json"

if ! command -v jq >/dev/null 2>&1; then
    printf 'Warning: jq not found. Skipping gemini settings merge.\n' >&2
    exit 0
fi

if [ ! -f "$TARGET" ]; then
    mkdir -p "$(dirname "$TARGET")"
    printf '%s\n' "$DESIRED" > "$TARGET"
    exit 0
fi

CURRENT="$(cat "$TARGET")"
MERGED="$(printf '%s' "$CURRENT" | jq --argjson d "$DESIRED" '.hooks = $d.hooks')"
printf '%s\n' "$MERGED" > "$TARGET"
```

- [ ] **Step 5: Add the Gemini tool doc**

Create `docs/tools/gemini.md` with:

````md
# Gemini CLI

Google Gemini CLI の dotfiles 管理内容をまとめたリファレンス。

## Managed Files

```text
home/dot_gemini/
  GEMINI.md.tmpl
  hooks/
    executable_pre-tool-use.sh
    executable_notification.sh
    executable_stop.sh
  run_apply-gemini-settings.sh
```

## Hooks

Gemini の global hooks は `~/.gemini/settings.json` で管理し、dotfiles では
各 hook ファイルを thin adapter として `~/.gemini/hooks/` に配置する。
実際の通知と preflight policy は `~/.agents/hooks/bin/` の shared core に集約する。
````

- [ ] **Step 6: Run Gemini tests and lint the new doc**

Run:

```bash
bats tests/test_gemini_settings.bats
markdownlint-cli2 docs/tools/gemini.md
```

Expected:

```text
ok 1 script exists
ok 2 new install: creates Gemini settings.json
ok 3 new install: config points to deployed hook adapters
Summary: 0 error(s)
```

- [ ] **Step 7: Commit the Gemini hook support**

Run:

```bash
git add home/dot_gemini tests/test_gemini_settings.bats docs/tools/gemini.md
git commit -m "feat: add gemini global hook adapters"
```

Expected:

```text
[dev ...] feat: add gemini global hook adapters
```

### Task 5: Update Shared Docs and Run End-to-End Verification

**Files:**

- Modify: `docs/tools/coding_agents.md`
- Modify: `docs/tools/chezmoi.md`
- Modify: `tests/test_chezmoi.bats`
- Test: `tests/test_hooks.bats`
- Test: `tests/test_claude_settings.bats`
- Test: `tests/test_codex_config.bats`
- Test: `tests/test_gemini_settings.bats`

- [ ] **Step 1: Update `docs/tools/coding_agents.md` to mention shared hooks**

Add this section after the existing "構成" section:

```md
## Shared Hooks

`~/.agents/hooks/` を coding agent 向け hook の共通基盤として使う。

| 区分 | パス | 用途 |
| --- | --- | --- |
| Shared core | `~/.agents/hooks/lib/` | `.env` 判定、危険 Bash 判定、通知 transport |
| Shared entrypoints | `~/.agents/hooks/bin/` | `check-preflight.sh` `notify-attention.sh` `notify-finished.sh` |
| Agent adapters | `~/.claude/hooks/` `~/.codex/hooks/` `~/.gemini/hooks/` | 各ツール固有の stdin/stdout 変換 |
```

- [ ] **Step 2: Update `docs/tools/chezmoi.md` to distinguish runtime hooks from apply scripts**

Append this subsection:

```md
### Runtime Hooks vs `.chezmoiscripts`

runtime hook は `home/dot_agents/hooks/` や `home/dot_claude/hooks/` のような
通常ファイルとして管理し、`chezmoi apply` でホームディレクトリへデプロイする。

`.chezmoiscripts/` や `run_` スクリプトは設定ファイルの生成・マージのために使い、
ランタイムでエージェントから直接呼ばれる hook 本体の置き場にはしない。
```

- [ ] **Step 3: Extend the chezmoi test to cover the new Gemini script and hook tree**

Add this test to `tests/test_chezmoi.bats`:

```bash
@test "chezmoi source includes shared and agent hook directories" {
    run fd . "$REPO_ROOT/$CHEZMOI_ROOT/dot_agents/hooks" -tf
    [ "$status" -eq 0 ]
    [[ "$output" == *"executable_check-preflight.sh"* ]]
    [[ "$output" == *"executable_notify-finished.sh"* ]]

    run fd . "$REPO_ROOT/$CHEZMOI_ROOT/dot_gemini/hooks" -tf
    [ "$status" -eq 0 ]
    [[ "$output" == *"executable_pre-tool-use.sh"* ]]
    [[ "$output" == *"executable_stop.sh"* ]]
}
```

- [ ] **Step 4: Run the full targeted verification set**

Run:

```bash
bats tests/test_hooks.bats
bats tests/test_claude_settings.bats
bats tests/test_codex_config.bats
bats tests/test_gemini_settings.bats
bats tests/test_chezmoi.bats
markdownlint-cli2 docs/tools/coding_agents.md docs/tools/claude_code_hooks.md docs/tools/codex.md docs/tools/gemini.md docs/tools/chezmoi.md
```

Expected:

```text
ok ... tests/test_hooks.bats
ok ... tests/test_claude_settings.bats
ok ... tests/test_codex_config.bats
ok ... tests/test_gemini_settings.bats
ok ... tests/test_chezmoi.bats
Summary: 0 error(s)
```

- [ ] **Step 5: Apply chezmoi locally and verify deployed hook files exist**

Run:

```bash
make apply
ls -la ~/.agents/hooks/bin
ls -la ~/.claude/hooks
ls -la ~/.codex/hooks
ls -la ~/.gemini/hooks
```

Expected:

```text
check-preflight.sh
notify-attention.sh
notify-finished.sh
pre-tool-use.sh
stop.sh
notification.sh
```

- [ ] **Step 6: Commit the remaining docs and verification changes**

Run:

```bash
git add docs/tools tests/test_chezmoi.bats
git commit -m "docs: document shared coding-agent hooks"
```

Expected:

```text
[dev ...] docs: document shared coding-agent hooks
```
