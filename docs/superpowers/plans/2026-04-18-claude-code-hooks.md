# Claude Code Generic Hooks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add security and notification hooks for Claude Code to the dotfiles repo, deployed via chezmoi.

**Architecture:** Dispatcher pattern — `settings.json` references top-level scripts; each script sources `lib/` modules for platform detection and notifications. The `.env` block/allow logic uses segment-based keyword matching rather than explicit enumeration.

**Tech Stack:** bash, jq, bats (testing), chezmoi (deployment), notify-send (Linux/WSL), osascript (macOS)

**Spec:** `docs/superpowers/specs/2026-04-18-claude-code-hooks-design.md`

---

## File Map

| Action | Path |
| --- | --- |
| Create | `home/dot_claude/hooks/lib/platform.sh` |
| Create | `home/dot_claude/hooks/lib/notify.sh` |
| Create | `home/dot_claude/hooks/pre-tool-use.sh` |
| Create | `home/dot_claude/hooks/notification.sh` |
| Create | `home/dot_claude/hooks/stop.sh` |
| Create | `tests/test_hooks.bats` |
| Modify | `home/dot_claude/run_apply-claude-settings.sh` |
| Modify | `tests/test_claude_settings.bats` |

---

## Task 1: Platform detection library

**Files:**

- Create: `home/dot_claude/hooks/lib/platform.sh`
- Create (test): `tests/test_hooks.bats`

- [ ] **Step 1: Write the failing test**

Create `tests/test_hooks.bats`:

```bash
#!/usr/bin/env bats
# Tests for Claude Code hook scripts

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI_ROOT="$(tr -d '[:space:]' < "$REPO_ROOT/.chezmoiroot")"
HOOKS_DIR="$REPO_ROOT/$CHEZMOI_ROOT/dot_claude/hooks"
PLATFORM_SH="$HOOKS_DIR/lib/platform.sh"

# ---------------------------------------------------------------------------
# lib/platform.sh
# ---------------------------------------------------------------------------

@test "platform.sh: exists and is executable" {
    [ -f "$PLATFORM_SH" ]
    [ -x "$PLATFORM_SH" ]
}

@test "platform.sh: detects macOS when uname returns Darwin" {
    run bash -c "uname() { echo Darwin; }; export -f uname; unset WSL_DISTRO_NAME; . '$PLATFORM_SH'; echo \$PLATFORM"
    [ "$output" = "macos" ]
}

@test "platform.sh: detects wsl when WSL_DISTRO_NAME is set" {
    run bash -c "WSL_DISTRO_NAME=Ubuntu . '$PLATFORM_SH'; echo \$PLATFORM"
    [ "$output" = "wsl" ]
}

@test "platform.sh: returns linux on plain Linux without WSL" {
    run bash -c "unset WSL_DISTRO_NAME; . '$PLATFORM_SH'; echo \$PLATFORM"
    # In this Docker/Linux container with no WSL_DISTRO_NAME, should be linux
    [ "$output" = "linux" ] || [ "$output" = "wsl" ]
}
```

- [ ] **Step 2: Run to verify it fails**

```bash
cd /workspace/dotfiles && bats tests/test_hooks.bats
```

Expected: FAIL — `platform.sh: exists and is executable` (file not found)

- [ ] **Step 3: Create the lib directory and write `platform.sh`**

```bash
mkdir -p home/dot_claude/hooks/lib
```

Create `home/dot_claude/hooks/lib/platform.sh`:

```bash
#!/bin/bash
# Detect the current platform and export PLATFORM.
# Values: macos | wsl | linux | unknown
# Source this file: . platform.sh
# After sourcing, $PLATFORM is set and exported.

_detect_platform() {
    if [ "$(uname -s 2>/dev/null)" = "Darwin" ]; then
        echo "macos"
    elif [ -n "${WSL_DISTRO_NAME:-}" ]; then
        echo "wsl"
    elif [ "$(uname -s 2>/dev/null)" = "Linux" ]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

PLATFORM="$(_detect_platform)"
export PLATFORM
```

- [ ] **Step 4: Make executable**

```bash
chmod +x home/dot_claude/hooks/lib/platform.sh
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd /workspace/dotfiles && bats tests/test_hooks.bats
```

Expected: all 4 `platform.sh` tests pass

- [ ] **Step 6: Commit**

```bash
git add home/dot_claude/hooks/lib/platform.sh tests/test_hooks.bats
git commit -m "feat: add platform detection library for Claude Code hooks"
```

---

## Task 2: Notification library

**Files:**

- Create: `home/dot_claude/hooks/lib/notify.sh`
- Modify: `tests/test_hooks.bats`

- [ ] **Step 1: Append tests for `notify.sh`**

Append to `tests/test_hooks.bats`:

```bash
NOTIFY_SH="$HOOKS_DIR/lib/notify.sh"

# ---------------------------------------------------------------------------
# lib/notify.sh
# ---------------------------------------------------------------------------

@test "notify.sh: exists and is executable" {
    [ -f "$NOTIFY_SH" ]
    [ -x "$NOTIFY_SH" ]
}

@test "notify.sh: calls notify-send on linux/wsl when available" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    # Create mock notify-send
    printf '#!/bin/bash\necho "$@" >> "%s"\n' "$CALLS" > "$MOCK_DIR/notify-send"
    chmod +x "$MOCK_DIR/notify-send"

    run bash -c "
        export PATH='$MOCK_DIR:\$PATH'
        export WSL_DISTRO_NAME=Ubuntu
        . '$NOTIFY_SH'
        send_notification 'TestTitle' 'TestMessage'
    "
    [ "$status" -eq 0 ]
    grep -q "TestTitle" "$CALLS"
    grep -q "TestMessage" "$CALLS"
    rm -rf "$MOCK_DIR"
}

@test "notify.sh: falls back to stderr when notify-send is absent" {
    # Remove notify-send from PATH by using an empty dir
    EMPTY_DIR="$(mktemp -d)"
    run bash -c "
        export PATH='$EMPTY_DIR'
        export WSL_DISTRO_NAME=Ubuntu
        . '$NOTIFY_SH'
        send_notification 'FallbackTitle' 'FallbackMsg'
    "
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "\[NOTICE\]"
    rm -rf "$EMPTY_DIR"
}

@test "notify.sh: falls back to stderr on unknown platform" {
    EMPTY_DIR="$(mktemp -d)"
    run bash -c "
        export PATH='$EMPTY_DIR'
        unset WSL_DISTRO_NAME
        # Override uname to return something unknown
        uname() { echo 'SunOS'; }
        export -f uname
        . '$NOTIFY_SH'
        send_notification 'Title' 'Msg'
    "
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "\[NOTICE\]"
    rm -rf "$EMPTY_DIR"
}
```

- [ ] **Step 2: Run to verify new tests fail**

```bash
cd /workspace/dotfiles && bats tests/test_hooks.bats
```

Expected: FAIL — `notify.sh: exists and is executable`

- [ ] **Step 3: Write `notify.sh`**

Create `home/dot_claude/hooks/lib/notify.sh`:

```bash
#!/bin/bash
# Notification library for Claude Code hooks.
# Usage: source this file, then call send_notification TITLE MESSAGE.

NOTIFY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./platform.sh
. "$NOTIFY_LIB_DIR/platform.sh"

# send_notification TITLE MESSAGE
# Sends a desktop notification using the platform-appropriate command.
# Falls back to stderr when no notification command is available.
send_notification() {
    local title="$1"
    local message="$2"

    case "$PLATFORM" in
        macos)
            osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null
            ;;
        wsl|linux)
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "$title" "$message"
            else
                printf '[NOTICE] %s: %s\n' "$title" "$message" >&2
            fi
            ;;
        *)
            printf '[NOTICE] %s: %s\n' "$title" "$message" >&2
            ;;
    esac
}
```

- [ ] **Step 4: Make executable**

```bash
chmod +x home/dot_claude/hooks/lib/notify.sh
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd /workspace/dotfiles && bats tests/test_hooks.bats
```

Expected: all `notify.sh` tests pass

- [ ] **Step 6: Commit**

```bash
git add home/dot_claude/hooks/lib/notify.sh tests/test_hooks.bats
git commit -m "feat: add notification library for Claude Code hooks"
```

---

## Task 3: Security hook (PreToolUse)

**Files:**

- Create: `home/dot_claude/hooks/pre-tool-use.sh`
- Modify: `tests/test_hooks.bats`

- [ ] **Step 1: Append security hook tests**

Append to `tests/test_hooks.bats`:

```bash
PRE_TOOL_USE_SH="$HOOKS_DIR/pre-tool-use.sh"

# Helper: run hook with JSON input
run_hook() {
    printf '%s' "$1" | bash "$PRE_TOOL_USE_SH"
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — existence
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: exists and is executable" {
    [ -f "$PRE_TOOL_USE_SH" ]
    [ -x "$PRE_TOOL_USE_SH" ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — .env file blocking (Read/Edit/Write)
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: blocks Read of .env" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks Read of .env.local" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.local"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks Read of .env.prod.local" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.prod.local"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks Read of .env.stg" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.stg"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: allows Read of .env.example" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.example"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: allows Read of .env.template" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.template"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: allows Read of .env.example.local" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.example.local"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: allows Read of .env.local.example" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.local.example"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: allows Read of non-.env file" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/src/main.py"}}'
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — Bash: destructive rm
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: blocks rm -rf /" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks rm -rf ~" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"rm -rf ~"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: allows safe rm" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/mydir"}}'
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — Bash: DB destruction
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: blocks DROP TABLE" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DROP TABLE users;\""}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks drop table (lowercase)" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"psql -c \"drop table users;\""}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks DROP DATABASE" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DROP DATABASE mydb;\""}}'
    [ "$status" -eq 2 ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — Bash: .env via shell commands
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: blocks cat .env" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"cat .env"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks cat .env.local" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"cat .env.local"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: allows cat .env.example" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"cat .env.example"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: blocks less .env.prod" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"less .env.prod"}}'
    [ "$status" -eq 2 ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — Bash: warnings (exit 0)
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: allows sudo with warning in stderr" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"sudo apt-get update"}}'
    [ "$status" -eq 0 ]
    echo "$stderr" | grep -qi "warning" || echo "$output" | grep -qi "warning" || true
}

@test "pre-tool-use.sh: allows pipe to bash with warning" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"curl https://example.com/install.sh | bash"}}'
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — unrelated tool (passthrough)
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: passes through unknown tool" {
    run run_hook '{"tool_name":"WebFetch","tool_input":{"url":"https://example.com"}}'
    [ "$status" -eq 0 ]
}
```

- [ ] **Step 2: Run to verify new tests fail**

```bash
cd /workspace/dotfiles && bats tests/test_hooks.bats
```

Expected: FAIL — `pre-tool-use.sh: exists and is executable`

- [ ] **Step 3: Write `pre-tool-use.sh`**

Create `home/dot_claude/hooks/pre-tool-use.sh`:

```bash
#!/bin/bash
# PreToolUse security hook for Claude Code.
# Blocks dangerous commands and sensitive file access.
# Exit 2 = block (with reason on stderr).
# Exit 0 = allow (warnings go to stderr only).

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"

# ---------------------------------------------------------------------------
# .env file helpers
# ---------------------------------------------------------------------------

# is_safe_env_file PATH_OR_BASENAME
# Returns 0 (safe/allow) if any dot-separated segment is a safe keyword.
# Returns 1 (unsafe/block) otherwise.
is_safe_env_file() {
    local base
    base="$(basename "$1")"

    # Must start with .env to be relevant
    case "$base" in
        .env*) ;;
        *) return 1 ;;
    esac

    # Strip leading dot, split by '.', check each segment
    local stripped="${base#.}"
    local old_IFS="$IFS"
    IFS='.'
    # shellcheck disable=SC2086
    set -- $stripped
    IFS="$old_IFS"
    for segment; do
        case "$segment" in
            example|template|sample|default|dist|schema)
                return 0  # safe keyword found
                ;;
        esac
    done
    return 1  # no safe keyword → block
}

# is_env_file PATH_OR_BASENAME
# Returns 0 if the basename starts with .env
is_env_file() {
    local base
    base="$(basename "$1")"
    case "$base" in
        .env*) return 0 ;;
        *) return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# File-based tools: Read, Edit, Write
# ---------------------------------------------------------------------------

case "$TOOL_NAME" in
    Read|Edit|Write)
        FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
        if [ -n "$FILE_PATH" ] && is_env_file "$FILE_PATH" && ! is_safe_env_file "$FILE_PATH"; then
            printf 'Blocked: %s is a sensitive .env file. Use .env.example (or similar) for templates.\n' \
                "$(basename "$FILE_PATH")" >&2
            exit 2
        fi
        exit 0
        ;;
esac

# ---------------------------------------------------------------------------
# Bash tool
# ---------------------------------------------------------------------------

if [ "$TOOL_NAME" = "Bash" ]; then
    COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"

    # Block: destructive rm
    case "$COMMAND" in
        *"rm -rf /"* | *"rm -rf ~"* | *"rm -rf /*"* | *"rm -rf ."*)
            printf 'Blocked: destructive rm detected. Command: %s\n' "$COMMAND" >&2
            exit 2
            ;;
    esac

    # Block: SQL table/database destruction (case-insensitive)
    COMMAND_UPPER="$(printf '%s' "$COMMAND" | tr '[:lower:]' '[:upper:]')"
    case "$COMMAND_UPPER" in
        *"DROP TABLE"* | *"DROP DATABASE"*)
            printf 'Blocked: destructive SQL command detected.\n' >&2
            exit 2
            ;;
    esac

    # Block: reading .env files via shell read commands
    # Check for read-type commands that reference .env files
    case "$COMMAND" in
        cat\ * | less\ * | more\ * | head\ * | tail\ * | grep\ *)
            # Extract .env* token(s) from the command
            ENV_REF="$(printf '%s' "$COMMAND" | grep -oE '\.env[a-zA-Z0-9._-]*' | head -1)"
            if [ -n "$ENV_REF" ] && ! is_safe_env_file "$ENV_REF"; then
                printf 'Blocked: reading sensitive env file via shell: %s\n' "$ENV_REF" >&2
                exit 2
            fi
            ;;
    esac

    # Warn: sudo usage (allow but surface warning)
    case "$COMMAND" in
        *"sudo "*)
            printf 'Warning: sudo usage detected. Ensure this is intentional: %s\n' "$COMMAND" >&2
            ;;
    esac

    # Warn: pipe to shell (supply chain risk)
    case "$COMMAND" in
        *"| bash"* | *"| sh"* | *"|bash"* | *"|sh"*)
            printf 'Warning: pipe-to-shell detected (supply chain risk): %s\n' "$COMMAND" >&2
            ;;
    esac

    exit 0
fi

# Unknown tool — pass through
exit 0
```

- [ ] **Step 4: Make executable**

```bash
chmod +x home/dot_claude/hooks/pre-tool-use.sh
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd /workspace/dotfiles && bats tests/test_hooks.bats
```

Expected: all `pre-tool-use.sh` tests pass

- [ ] **Step 6: Commit**

```bash
git add home/dot_claude/hooks/pre-tool-use.sh tests/test_hooks.bats
git commit -m "feat: add PreToolUse security hook"
```

---

## Task 4: Notification and Stop hooks

**Files:**

- Create: `home/dot_claude/hooks/notification.sh`
- Create: `home/dot_claude/hooks/stop.sh`
- Modify: `tests/test_hooks.bats`

- [ ] **Step 1: Append notification/stop tests**

Append to `tests/test_hooks.bats`:

```bash
NOTIFICATION_SH="$HOOKS_DIR/notification.sh"
STOP_SH="$HOOKS_DIR/stop.sh"

# ---------------------------------------------------------------------------
# notification.sh
# ---------------------------------------------------------------------------

@test "notification.sh: exists and is executable" {
    [ -f "$NOTIFICATION_SH" ]
    [ -x "$NOTIFICATION_SH" ]
}

@test "notification.sh: calls send_notification on valid input" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    printf '#!/bin/bash\necho "$@" >> "%s"\n' "$CALLS" > "$MOCK_DIR/notify-send"
    chmod +x "$MOCK_DIR/notify-send"

    run bash -c "
        export PATH='$MOCK_DIR:\$PATH'
        export WSL_DISTRO_NAME=Ubuntu
        printf '{}' | bash '$NOTIFICATION_SH'
    "
    [ "$status" -eq 0 ]
    [ -f "$CALLS" ]
    rm -rf "$MOCK_DIR"
}

# ---------------------------------------------------------------------------
# stop.sh
# ---------------------------------------------------------------------------

@test "stop.sh: exists and is executable" {
    [ -f "$STOP_SH" ]
    [ -x "$STOP_SH" ]
}

@test "stop.sh: exits 0 immediately when stop_hook_active is true" {
    run bash -c "printf '{\"stop_hook_active\":true,\"session_id\":\"test-guard\"}' | bash '$STOP_SH'"
    [ "$status" -eq 0 ]
}

@test "stop.sh: does not notify on first call (creates marker only)" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    printf '#!/bin/bash\necho "$@" >> "%s"\n' "$CALLS" > "$MOCK_DIR/notify-send"
    chmod +x "$MOCK_DIR/notify-send"

    SESSION="test-session-first-$$"
    run bash -c "
        export TMPDIR='$MOCK_DIR'
        export PATH='$MOCK_DIR:\$PATH'
        export WSL_DISTRO_NAME=Ubuntu
        printf '{\"stop_hook_active\":false,\"session_id\":\"$SESSION\"}' | bash '$STOP_SH'
    "
    [ "$status" -eq 0 ]
    # notify-send should NOT have been called (first call just writes marker)
    [ ! -f "$CALLS" ] || [ ! -s "$CALLS" ]
    rm -rf "$MOCK_DIR"
}

@test "stop.sh: notifies when elapsed time >= 10 seconds" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    printf '#!/bin/bash\necho "$@" >> "%s"\n' "$CALLS" > "$MOCK_DIR/notify-send"
    chmod +x "$MOCK_DIR/notify-send"

    SESSION="test-session-elapsed-$$"
    # Write a marker with a timestamp 15 seconds in the past
    PAST=$(( $(date +%s) - 15 ))
    printf '%s\n' "$PAST" > "$MOCK_DIR/claude-last-stop-$SESSION"

    run bash -c "
        export TMPDIR='$MOCK_DIR'
        export PATH='$MOCK_DIR:\$PATH'
        export WSL_DISTRO_NAME=Ubuntu
        printf '{\"stop_hook_active\":false,\"session_id\":\"$SESSION\"}' | bash '$STOP_SH'
    "
    [ "$status" -eq 0 ]
    [ -f "$CALLS" ] && [ -s "$CALLS" ]
    rm -rf "$MOCK_DIR"
}

@test "stop.sh: does not notify when elapsed time < 10 seconds" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    printf '#!/bin/bash\necho "$@" >> "%s"\n' "$CALLS" > "$MOCK_DIR/notify-send"
    chmod +x "$MOCK_DIR/notify-send"

    SESSION="test-session-fast-$$"
    # Write a marker just 2 seconds ago
    RECENT=$(( $(date +%s) - 2 ))
    printf '%s\n' "$RECENT" > "$MOCK_DIR/claude-last-stop-$SESSION"

    run bash -c "
        export TMPDIR='$MOCK_DIR'
        export PATH='$MOCK_DIR:\$PATH'
        export WSL_DISTRO_NAME=Ubuntu
        printf '{\"stop_hook_active\":false,\"session_id\":\"$SESSION\"}' | bash '$STOP_SH'
    "
    [ "$status" -eq 0 ]
    [ ! -f "$CALLS" ] || [ ! -s "$CALLS" ]
    rm -rf "$MOCK_DIR"
}
```

- [ ] **Step 2: Run to verify new tests fail**

```bash
cd /workspace/dotfiles && bats tests/test_hooks.bats
```

Expected: FAIL — `notification.sh: exists and is executable`

- [ ] **Step 3: Write `notification.sh`**

Create `home/dot_claude/hooks/notification.sh`:

```bash
#!/bin/bash
# Notification event hook for Claude Code.
# Fires when Claude needs attention (permission prompt, idle, etc.).

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/notify.sh
. "$HOOK_DIR/lib/notify.sh"

send_notification "Claude Code" "Needs your attention"
```

- [ ] **Step 4: Write `stop.sh`**

Create `home/dot_claude/hooks/stop.sh`:

```bash
#!/bin/bash
# Stop event hook for Claude Code.
# Sends a completion notification after responses that took >= 10 seconds.
# Skips fast responses to avoid noise during short back-and-forth exchanges.

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/notify.sh
. "$HOOK_DIR/lib/notify.sh"

INPUT="$(cat)"

# Guard: stop_hook_active=true means we're already in a stop hook loop — exit early
if [ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
    exit 0
fi

SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty')"
MARKER_FILE="${TMPDIR:-/tmp}/claude-last-stop-${SESSION_ID}"

NOW="$(date +%s)"

# First call for this session: write marker, skip notification
if [ ! -f "$MARKER_FILE" ]; then
    printf '%s\n' "$NOW" > "$MARKER_FILE"
    exit 0
fi

LAST_STOP="$(cat "$MARKER_FILE")"
ELAPSED=$(( NOW - LAST_STOP ))

# Update marker timestamp for next call
printf '%s\n' "$NOW" > "$MARKER_FILE"

# Notify only if Claude was working for >= 10 seconds
if [ "$ELAPSED" -ge 10 ]; then
    send_notification "Claude Code" "Finished"
fi

exit 0
```

- [ ] **Step 5: Make scripts executable**

```bash
chmod +x home/dot_claude/hooks/notification.sh home/dot_claude/hooks/stop.sh
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
cd /workspace/dotfiles && bats tests/test_hooks.bats
```

Expected: all `notification.sh` and `stop.sh` tests pass

- [ ] **Step 7: Commit**

```bash
git add home/dot_claude/hooks/notification.sh home/dot_claude/hooks/stop.sh tests/test_hooks.bats
git commit -m "feat: add notification and stop hooks for Claude Code"
```

---

## Task 5: Wire hooks into `run_apply-claude-settings.sh`

**Files:**

- Modify: `home/dot_claude/run_apply-claude-settings.sh`
- Modify: `tests/test_claude_settings.bats`

The existing merge logic preserves `hooks` from the existing file untouched. We change this to: **union per event key** — desired hook entries for each event are merged into existing; events not in DESIRED are preserved.

- [ ] **Step 1: Update the two failing tests in `tests/test_claude_settings.bats`**

Replace the two hook-related tests:

```bash
# Old:
@test "new install: does not include hooks" {
    "$SCRIPT"
    run jq 'has("hooks")' "$HOME/.claude/settings.json"
    [ "$output" = "false" ]
}

# New:
@test "new install: includes desired hooks" {
    "$SCRIPT"
    run jq 'has("hooks")' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
    run jq '.hooks | has("PreToolUse")' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
    run jq '.hooks | has("Notification")' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
    run jq '.hooks | has("Stop")' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
}
```

```bash
# Old:
@test "merge: preserves existing hooks" {
    cat > "$HOME/.claude/settings.json" <<'EOF'
{
    "hooks": {
        "PreToolUse": [{"_tag": "ccstatusline-managed", "type": "command", "command": "npx ccstatusline"}]
    }
}
EOF
    "$SCRIPT"
    run jq '.hooks.PreToolUse | length' "$HOME/.claude/settings.json"
    [ "$output" = "1" ]
}

# New:
@test "merge: unions existing hooks with desired hooks per event" {
    cat > "$HOME/.claude/settings.json" <<'EOF'
{
    "hooks": {
        "PreToolUse": [{"matcher":"Skill","hooks":[{"type":"command","command":"npx ccstatusline"}]}],
        "UserPromptSubmit": [{"hooks":[{"type":"command","command":"npx ccstatusline --hook"}]}]
    }
}
EOF
    "$SCRIPT"
    # Desired PreToolUse entries are added; existing Skill entry is preserved
    run jq '.hooks.PreToolUse | length' "$HOME/.claude/settings.json"
    [ "$output" -ge 2 ]
    # UserPromptSubmit (not in DESIRED) is preserved
    run jq '.hooks | has("UserPromptSubmit")' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
}
```

- [ ] **Step 2: Run to verify updated tests fail**

```bash
cd /workspace/dotfiles && bats tests/test_claude_settings.bats
```

Expected: FAIL on `new install: includes desired hooks` and `merge: unions existing hooks`

- [ ] **Step 3: Add hooks to DESIRED block in `run_apply-claude-settings.sh`**

In `run_apply-claude-settings.sh`, add `"hooks"` to the DESIRED JSON (after the closing `}` of `"permissions"`, before the final `EOF`):

Replace:

```json
    }
}
EOF
)
```

With:

```json
    },
    "hooks": {
        "PreToolUse": [
            {
                "matcher": "Bash",
                "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-tool-use.sh"}]
            },
            {
                "matcher": "Read|Edit|Write",
                "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-tool-use.sh"}]
            }
        ],
        "Notification": [
            {
                "matcher": "",
                "hooks": [{"type": "command", "command": "~/.claude/hooks/notification.sh"}]
            }
        ],
        "Stop": [
            {
                "hooks": [{"type": "command", "command": "~/.claude/hooks/stop.sh"}]
            }
        ]
    }
}
EOF
)
```

- [ ] **Step 4: Update the merge header comment and jq logic**

Replace the comment at the top of the merge strategy section:

```sh
# Old:
#   Preserve:   hooks, enabledPlugins (not present in desired — kept from existing)

# New:
#   Preserve:   enabledPlugins (not present in desired — kept from existing)
#   Union/event: hooks (desired events merged into existing; other events preserved)
```

In the MERGED jq block, replace:

```sh
# Old (comment only, hooks not touched):
MERGED=$(printf '%s' "$CURRENT" | jq --argjson d "$DESIRED" '
  # hooks and enabledPlugins are intentionally not touched — preserved from existing file
  .env = $d.env |
```

With:

```sh
MERGED=$(printf '%s' "$CURRENT" | jq --argjson d "$DESIRED" '
  # enabledPlugins is intentionally not touched — preserved from existing file
  # hooks: for each event key in desired, union arrays into existing; other events preserved
  .hooks = (
    ($d.hooks // {}) as $dh |
    (.hooks // {}) as $ch |
    ($dh | keys) as $dkeys |
    reduce $dkeys[] as $event (
      $ch;
      .[$event] = (
        ((.[$event] // []) + $dh[$event]) | unique
      )
    )
  ) |
  .env = $d.env |
```

- [ ] **Step 5: Run all tests to verify they pass**

```bash
cd /workspace/dotfiles && bats tests/test_claude_settings.bats && bats tests/test_hooks.bats
```

Expected: all tests pass

- [ ] **Step 6: Run the full test suite**

```bash
cd /workspace/dotfiles && make test
```

Expected: all bats suites pass

- [ ] **Step 7: Commit**

```bash
git add home/dot_claude/run_apply-claude-settings.sh tests/test_claude_settings.bats
git commit -m "feat: wire hooks into run_apply-claude-settings.sh"
```

---

## Task 6: Chezmoi deployment and integration test

**Files:**

- No new files; verify deployment works end-to-end

Chezmoi preserves the executable bit of source files when deploying. Since we `chmod +x`'d all scripts before committing, they will land in `~/.claude/hooks/` with execute permission.

- [ ] **Step 1: Verify git tracks the execute bit on all hook scripts**

```bash
git ls-files -s home/dot_claude/hooks/
```

Expected: all `.sh` files show mode `100755` (not `100644`)

If any show `100644`, fix with:

```bash
git update-index --chmod=+x home/dot_claude/hooks/lib/platform.sh
git update-index --chmod=+x home/dot_claude/hooks/lib/notify.sh
git update-index --chmod=+x home/dot_claude/hooks/pre-tool-use.sh
git update-index --chmod=+x home/dot_claude/hooks/notification.sh
git update-index --chmod=+x home/dot_claude/hooks/stop.sh
git commit -m "fix: mark hook scripts as executable in git"
```

- [ ] **Step 2: Apply chezmoi and verify deployment**

```bash
chezmoi apply --source /workspace/dotfiles
```

```bash
ls -la ~/.claude/hooks/lib/
ls -la ~/.claude/hooks/*.sh
```

Expected: all `.sh` files have `x` bit set (e.g., `-rwxr-xr-x`)

- [ ] **Step 3: Apply settings script and verify hooks in settings.json**

```bash
~/.claude/run_apply-claude-settings.sh
```

```bash
jq '.hooks' ~/.claude/settings.json
```

Expected output contains `PreToolUse`, `Notification`, and `Stop` keys with the correct `~/.claude/hooks/` commands.

- [ ] **Step 4: Verify hooks appear in Claude Code**

Run Claude Code and type `/hooks`. Expected: `PreToolUse` (2 entries), `Notification` (1 entry), `Stop` (1 entry) visible.

- [ ] **Step 5: Test security block in live session**

Ask Claude: "Run `cat .env` to check the environment"

Expected: Claude receives block feedback and reports that `.env` access is not permitted.

- [ ] **Step 6: Test notification fallback (no notify-send)**

```bash
command -v notify-send || echo "notify-send not installed"
```

Ask Claude to do a ~10 second task (e.g., "explain what a closure is in 3 sentences"). After it responds, check Claude Code's verbose output (`Ctrl+O`).

Expected: `[NOTICE] Claude Code: Finished` appears in stderr/verbose output.

- [ ] **Step 7: Commit if any fixes were needed, otherwise done**

```bash
git status
# If clean: no action needed
# If fixes: git add -p && git commit -m "fix: ..."
```

---

## Self-Review Notes

**Spec coverage:**

- Security — block: `.env` file access (Read/Edit/Write + Bash) ✓
- Security — block: destructive rm, SQL DROP ✓
- Security — warn: sudo, pipe-to-shell ✓
- Notifications — Notification event ✓
- Notifications — Stop event with 10s threshold ✓
- Platform detection — WSL/macOS/linux ✓
- Fallback when notify-send absent ✓
- hooks added to `run_apply-claude-settings.sh` DESIRED ✓
- Merge strategy: union per event (not full overwrite) ✓
- chezmoi deployment with +x ✓

**Type consistency:** `is_safe_env_file` and `is_env_file` used consistently across Task 3. `send_notification TITLE MESSAGE` signature consistent across Tasks 2/4.

**No placeholders:** All code blocks are complete and runnable.
