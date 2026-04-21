# Agent Notification Signals Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the shared agent notification transport with an event-driven signal system that supports toast and sound channels across Claude Code, Codex CLI, and Gemini CLI, with WSL-first sound behavior and room for future user-configurable policy.

**Architecture:** Keep hook payload parsing and agent-specific return behavior inside the thin adapters under `home/dot_claude/`, `home/dot_gemini/`, and `home/dot_codex/`, while moving all signal semantics, capability detection, channel selection, warning suppression, and default event policy into `home/dot_agents/hooks/lib/executable_notify.sh`. Add shared entrypoints `agent-signal`, `agent-attention`, `agent-finished`, and `agent-danger`, then update adapters and tests to call the new interface.

**Tech Stack:** bash, jq, bats, chezmoi, markdownlint-cli2, shellcheck

---

## File Map

### Create

| Path | Responsibility |
| --- | --- |
| `home/dot_agents/hooks/bin/executable_agent-signal.sh` | Shared signal entrypoint that calls `emit_agent_signal` |
| `home/dot_agents/hooks/bin/executable_agent-attention.sh` | Thin wrapper for the `attention` signal |
| `home/dot_agents/hooks/bin/executable_agent-finished.sh` | Thin wrapper for the `finished` signal |
| `home/dot_agents/hooks/bin/executable_agent-danger.sh` | Thin wrapper for the `danger` signal |
| `docs/tools/coding_agents_notifications.md` | Optional focused doc for shared notification behavior if the existing tool docs become too noisy |

### Modify

| Path | Responsibility |
| --- | --- |
| `home/dot_agents/hooks/lib/executable_notify.sh` | Replace `send_notification` with event-driven signal functions and channel resolution |
| `home/dot_claude/hooks/executable_notification.sh` | Call shared `attention` wrapper |
| `home/dot_claude/hooks/executable_stop.sh` | Call shared `finished` wrapper |
| `home/dot_claude/hooks/executable_pre-tool-use.sh` | Emit `danger` only when shared preflight denies |
| `home/dot_gemini/hooks/executable_notification.sh` | Call shared `attention` wrapper |
| `home/dot_gemini/hooks/executable_stop.sh` | Call shared `finished` wrapper |
| `home/dot_gemini/hooks/executable_pre-tool-use.sh` | Emit `danger` only when shared preflight denies |
| `home/dot_codex/hooks/executable_stop.sh` | Call shared `finished` wrapper |
| `home/dot_codex/hooks/executable_pre-tool-use.sh` | Emit `danger` only when shared preflight denies while preserving Codex JSON output |
| `tests/test_hooks.bats` | Shared runtime and Claude adapter coverage |
| `tests/test_gemini_settings.bats` | Gemini adapter expectations and shared runtime deployment |
| `tests/test_codex_config.bats` | Codex adapter expectations and wrapper integration |
| `docs/tools/gemini.md` | Update hook doc names and behavior |
| `docs/superpowers/specs/2026-04-21-agent-hooks-unification-design.md` | Align earlier architecture spec with new signal names |

### No Change Expected

| Path | Reason |
| --- | --- |
| `home/dot_claude/run_apply-claude-settings.sh` | Hook event wiring stays the same |
| `home/dot_gemini/run_apply-gemini-settings.sh` | Hook event wiring stays the same |
| `home/dot_codex/run_apply-codex-config.sh` | Global config format stays the same |
| `home/dot_codex/private_hooks.json.tmpl` | Hook filenames stay the same |

---

## Prerequisites

Use the repo-local chezmoi source explicitly:

```bash
alias cm='chezmoi --source /workspace/dotfiles'
```

Verify core tools before editing:

```bash
command -v jq
command -v bats
command -v markdownlint-cli2
command -v shellcheck
```

Expected: all commands print a path and exit `0`.

---

### Task 1: Replace the shared notification library with event-driven signal logic

**Files:**

- Modify: `home/dot_agents/hooks/lib/executable_notify.sh`
- Create: `home/dot_agents/hooks/bin/executable_agent-signal.sh`
- Create: `home/dot_agents/hooks/bin/executable_agent-attention.sh`
- Create: `home/dot_agents/hooks/bin/executable_agent-finished.sh`
- Create: `home/dot_agents/hooks/bin/executable_agent-danger.sh`
- Test: `tests/test_hooks.bats`

- [ ] **Step 1: Write failing shared-runtime tests for the new signal entrypoints**

Append these tests to `tests/test_hooks.bats` near the existing shared notification tests:

```bash
@test "agent-signal: attention wrapper delegates to shared runtime" {
    setup_shared_hooks_home
    run env HOME="$SHARED_HOOKS_HOME" bash "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-attention.sh" "Claude Code"
    teardown_shared_hooks_home
    [ "$status" -eq 0 ]
}

@test "notify.sh: WSL attention sound uses play when available" {
    setup_shared_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    cat > "$MOCK_DIR/play" <<EOF
#!/bin/bash
printf '%s\n' "\$*" >> "$CALLS"
EOF
    chmod +x "$MOCK_DIR/play"

    run env HOME="$SHARED_HOOKS_HOME" PATH="$MOCK_DIR:$PATH" WSL_DISTRO_NAME=Ubuntu bash -c '
        . "$HOME/.agents/hooks/lib/notify.sh"
        emit_agent_signal attention "Claude Code"
    '

    [ "$status" -eq 0 ]
    grep -q "sine 784" "$CALLS"
    rm -rf "$MOCK_DIR"
    teardown_shared_hooks_home
}

@test "notify.sh: missing sound command warns once with checked commands" {
    setup_shared_hooks_home
    EMPTY_DIR="$(mktemp -d)"

    run env HOME="$SHARED_HOOKS_HOME" PATH="$EMPTY_DIR" WSL_DISTRO_NAME=Ubuntu bash -c '
        . "$HOME/.agents/hooks/lib/notify.sh"
        emit_agent_signal finished "Gemini" 2>&1
        emit_agent_signal finished "Gemini" 2>&1
    '

    [ "$status" -eq 0 ]
    [[ "$output" == *"[agent-signal]"* ]]
    [[ "$output" == *"sound checked: play"* ]]
    [ "$(printf '%s' "$output" | grep -c '\[agent-signal\]')" -eq 1 ]
    rm -rf "$EMPTY_DIR"
    teardown_shared_hooks_home
}
```

- [ ] **Step 2: Run the focused tests and confirm they fail**

Run:

```bash
bats tests/test_hooks.bats --filter "agent-signal:|notify.sh: WSL attention sound uses play when available|notify.sh: missing sound command warns once with checked commands"
```

Expected: `FAIL` because `emit_agent_signal` and the new wrapper scripts do not exist yet.

- [ ] **Step 3: Replace `home/dot_agents/hooks/lib/executable_notify.sh` with the shared signal runtime**

Use this complete file content:

```bash
#!/bin/bash
# Shared signal runtime for agent hooks.
# Source this file, then call emit_agent_signal EVENT AGENT [MESSAGE].

NOTIFY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$NOTIFY_LIB_DIR/platform.sh"

_agent_signal_tmpdir() {
    printf '%s\n' "${TMPDIR:-/tmp}"
}

_agent_signal_warn_marker() {
    local key="$1"
    printf '%s/%s\n' "$(_agent_signal_tmpdir)" "agent-signal-${USER:-unknown}-${key}.warned"
}

warn_agent_signal_once() {
    local key="$1"
    shift
    local marker
    marker="$(_agent_signal_warn_marker "$key")"
    if [ -e "$marker" ]; then
        return 0
    fi
    : > "$marker"
    printf '%s\n' "$@" >&2
}

resolve_signal_policy() {
    local event="$1"
    case "$PLATFORM" in
        wsl) printf 'sound\n' ;;
        macos|linux) printf 'toast+sound\n' ;;
        *) printf 'sound\n' ;;
    esac
}

linux_sound_name() {
    case "$1" in
        attention) printf 'message-new-instant\n' ;;
        finished) printf 'complete\n' ;;
        danger) printf 'dialog-warning\n' ;;
        *) printf 'dialog-information\n' ;;
    esac
}

macos_sound_name() {
    case "$1" in
        attention) printf 'Glass\n' ;;
        finished) printf 'Hero\n' ;;
        danger) printf 'Basso\n' ;;
        *) printf 'Glass\n' ;;
    esac
}

run_wsl_sound() {
    case "$1" in
        attention)
            play -n synth 0.22 sine 784 vol 0.12 fade q 0.01 0.22 0.06
            ;;
        finished)
            play -n synth 0.18 sine 740 vol 0.12 fade q 0.01 0.18 0.05
            sleep 0.3
            play -n synth 0.18 sine 988 vol 0.10 fade q 0.01 0.18 0.05
            ;;
        danger)
            play -n synth 0.28 triangle 660-990 vol 0.11 fade q 0.01 0.28 0.08
            ;;
        *)
            return 1
            ;;
    esac
}

run_toast_with_sound() {
    local event="$1"
    local agent="$2"
    local message="$3"
    case "$PLATFORM" in
        linux)
            if command -v notify-send >/dev/null 2>&1; then
                notify-send --hint="string:sound-name:$(linux_sound_name "$event")" "$agent" "$message"
                return 0
            fi
            ;;
        macos)
            if command -v osascript >/dev/null 2>&1; then
                osascript -e "display notification \"$message\" with title \"$agent\" sound name \"$(macos_sound_name "$event")\""
                return 0
            fi
            ;;
    esac
    return 1
}

run_toast_only() {
    local agent="$1"
    local message="$2"
    case "$PLATFORM" in
        linux)
            command -v notify-send >/dev/null 2>&1 && notify-send "$agent" "$message"
            ;;
        macos)
            command -v osascript >/dev/null 2>&1 && osascript -e "display notification \"$message\" with title \"$agent\""
            ;;
        *)
            return 1
            ;;
    esac
}

run_sound_only() {
    local event="$1"
    case "$PLATFORM" in
        wsl)
            command -v play >/dev/null 2>&1 || return 1
            run_wsl_sound "$event"
            ;;
        linux)
            command -v play >/dev/null 2>&1 || return 1
            case "$event" in
                attention) play -n synth 0.16 sine 880 vol 0.10 fade q 0.01 0.16 0.05 ;;
                finished) play -n synth 0.14 sine 740 vol 0.10 fade q 0.01 0.14 0.04 ; sleep 0.2 ; play -n synth 0.14 sine 988 vol 0.08 fade q 0.01 0.14 0.04 ;;
                danger) play -n synth 0.20 triangle 660-990 vol 0.10 fade q 0.01 0.20 0.06 ;;
                *) return 1 ;;
            esac
            ;;
        macos)
            if command -v afplay >/dev/null 2>&1; then
                afplay "/System/Library/Sounds/$(macos_sound_name "$event").aiff"
                return 0
            fi
            command -v osascript >/dev/null 2>&1 && osascript -e "beep"
            ;;
        *)
            return 1
            ;;
    esac
}

warn_missing_channels() {
    local event="$1"
    local policy="$2"
    local toast_available="$3"
    local sound_available="$4"
    warn_agent_signal_once \
        "${PLATFORM}-${policy}-${toast_available}-${sound_available}" \
        "[agent-signal] requested channels unavailable" \
        "platform=$PLATFORM event=$event policy=$policy" \
        "toast available: $toast_available" \
        "sound available: $sound_available" \
        "toast checked: notify-send osascript" \
        "sound checked: play afplay osascript"
}

default_signal_message() {
    case "$1" in
        attention) printf 'Needs your attention\n' ;;
        finished) printf 'Finished\n' ;;
        danger) printf 'Dangerous command blocked\n' ;;
        *) printf 'Signal\n' ;;
    esac
}

emit_agent_signal() {
    local event="$1"
    local agent="$2"
    local message="${3:-$(default_signal_message "$event")}"
    local policy toast_available sound_available

    policy="$(resolve_signal_policy "$event")"
    toast_available="none"
    sound_available="none"

    if run_toast_with_sound "$event" "$agent" "$message"; then
        return 0
    fi

    if run_toast_only "$agent" "$message" >/dev/null 2>&1; then
        toast_available="configured"
    fi
    if run_sound_only "$event" >/dev/null 2>&1; then
        sound_available="configured"
    fi

    case "$policy" in
        toast)
            run_toast_only "$agent" "$message" && return 0
            ;;
        sound)
            run_sound_only "$event" && return 0
            ;;
        toast+sound)
            run_toast_only "$agent" "$message" || true
            run_sound_only "$event" || true
            if run_toast_only "$agent" "$message" >/dev/null 2>&1 || run_sound_only "$event" >/dev/null 2>&1; then
                warn_missing_channels "$event" "$policy" "$toast_available" "$sound_available"
                return 0
            fi
            ;;
    esac

    warn_missing_channels "$event" "$policy" "$toast_available" "$sound_available"
    return 0
}
```

- [ ] **Step 4: Add the new shared wrapper scripts**

Create these exact files:

`home/dot_agents/hooks/bin/executable_agent-signal.sh`

```bash
#!/bin/bash
# Shared signal entrypoint.
# shellcheck disable=SC1090,SC1091
. ~/.agents/hooks/lib/notify.sh

exec bash -lc 'emit_agent_signal "$1" "$2" "$3"' -- "${1:-}" "${2:-Agent}" "${3:-}"
```

`home/dot_agents/hooks/bin/executable_agent-attention.sh`

```bash
#!/bin/bash
# Shared attention signal wrapper.

exec "$HOME/.agents/hooks/bin/agent-signal" attention "${1:-Agent}" "${2:-Needs your attention}"
```

`home/dot_agents/hooks/bin/executable_agent-finished.sh`

```bash
#!/bin/bash
# Shared finished signal wrapper.

exec "$HOME/.agents/hooks/bin/agent-signal" finished "${1:-Agent}" "${2:-Finished}"
```

`home/dot_agents/hooks/bin/executable_agent-danger.sh`

```bash
#!/bin/bash
# Shared danger signal wrapper.

exec "$HOME/.agents/hooks/bin/agent-signal" danger "${1:-Agent}" "${2:-Dangerous command blocked}"
```

- [ ] **Step 5: Run the focused tests and make them pass**

Run:

```bash
bats tests/test_hooks.bats --filter "agent-signal:|notify.sh: WSL attention sound uses play when available|notify.sh: missing sound command warns once with checked commands"
```

Expected: `PASS`.

- [ ] **Step 6: Commit the shared signal runtime**

```bash
git add home/dot_agents/hooks/lib/executable_notify.sh home/dot_agents/hooks/bin/executable_agent-signal.sh home/dot_agents/hooks/bin/executable_agent-attention.sh home/dot_agents/hooks/bin/executable_agent-finished.sh home/dot_agents/hooks/bin/executable_agent-danger.sh tests/test_hooks.bats
git commit -m "feat: add shared agent signal runtime"
```

---

### Task 2: Update Claude and Gemini adapters to emit semantic signals

**Files:**

- Modify: `home/dot_claude/hooks/executable_notification.sh`
- Modify: `home/dot_claude/hooks/executable_stop.sh`
- Modify: `home/dot_claude/hooks/executable_pre-tool-use.sh`
- Modify: `home/dot_gemini/hooks/executable_notification.sh`
- Modify: `home/dot_gemini/hooks/executable_stop.sh`
- Modify: `home/dot_gemini/hooks/executable_pre-tool-use.sh`
- Test: `tests/test_hooks.bats`
- Test: `tests/test_gemini_settings.bats`

- [ ] **Step 1: Write failing adapter tests for danger signal emission**

Add these tests:

```bash
@test "claude pre-tool-use emits danger signal on denied command" {
    setup_shared_hooks_home
    mkdir -p "$SHARED_HOOKS_HOME/.agents/hooks/bin" "$SHARED_HOOKS_HOME/.claude/hooks"
    cp "$REPO_ROOT/home/dot_claude/hooks/executable_pre-tool-use.sh" "$SHARED_HOOKS_HOME/.claude/hooks/pre-tool-use.sh"
    chmod +x "$SHARED_HOOKS_HOME/.claude/hooks/pre-tool-use.sh"
    cat > "$SHARED_HOOKS_HOME/.agents/hooks/bin/check-preflight.sh" <<'EOF'
#!/bin/bash
exit 2
EOF
    cat > "$SHARED_HOOKS_HOME/.agents/hooks/bin/agent-danger" <<'EOF'
#!/bin/bash
printf '%s\n' "$*"
EOF
    chmod +x "$SHARED_HOOKS_HOME/.agents/hooks/bin/check-preflight.sh" "$SHARED_HOOKS_HOME/.agents/hooks/bin/agent-danger"

    run env HOME="$SHARED_HOOKS_HOME" bash "$SHARED_HOOKS_HOME/.claude/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}
EOF

    [ "$status" -eq 2 ]
    [[ "$output" == *"Claude Code"* ]]
}

@test "gemini pre-tool-use emits danger signal on denied command" {
    install_shared_hooks_home "$HOME"
    install_gemini_hooks_home "$HOME"
    cat > "$HOME/.agents/hooks/bin/check-preflight.sh" <<'EOF'
#!/bin/bash
exit 2
EOF
    cat > "$HOME/.agents/hooks/bin/agent-danger" <<'EOF'
#!/bin/bash
printf '%s\n' "$*"
EOF
    chmod +x "$HOME/.agents/hooks/bin/check-preflight.sh" "$HOME/.agents/hooks/bin/agent-danger"

    run env HOME="$HOME" bash "$HOME/.gemini/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}
EOF

    [ "$status" -eq 2 ]
    [[ "$output" == *"Gemini"* ]]
}
```

- [ ] **Step 2: Run the focused tests and confirm they fail**

Run:

```bash
bats tests/test_hooks.bats --filter "claude pre-tool-use emits danger signal on denied command"
bats tests/test_gemini_settings.bats --filter "gemini pre-tool-use emits danger signal on denied command"
```

Expected: `FAIL` because the adapters do not emit `agent-danger` yet.

- [ ] **Step 3: Update the Claude adapters**

Use these file contents:

`home/dot_claude/hooks/executable_notification.sh`

```bash
#!/bin/bash
# Claude Code attention notification adapter.

cat >/dev/null

SHARED_ATTENTION="$HOME/.agents/hooks/bin/agent-attention"

if [ ! -x "$SHARED_ATTENTION" ]; then
    printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_ATTENTION" >&2
    exit 2
fi

exec "$SHARED_ATTENTION" "Claude Code" "Needs your attention"
```

`home/dot_claude/hooks/executable_stop.sh`

```bash
#!/bin/bash
# Claude Code stop adapter.
# Keeps Claude-specific timing and loop-guard behavior, then delegates to the shared signal runtime.

INPUT="$(cat)"
SHARED_FINISHED="$HOME/.agents/hooks/bin/agent-finished"

if [ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
    exit 0
fi

SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty')"
if [ -z "$SESSION_ID" ]; then
    exit 0
fi
MARKER_FILE="${TMPDIR:-/tmp}/claude-last-stop-${SESSION_ID}"

NOW="$(date +%s)"

if [ ! -f "$MARKER_FILE" ]; then
    printf '%s\n' "$NOW" > "$MARKER_FILE"
    exit 0
fi

LAST_STOP="$(cat "$MARKER_FILE")"
ELAPSED=$(( NOW - LAST_STOP ))
printf '%s\n' "$NOW" > "$MARKER_FILE"

if [ "$ELAPSED" -ge 10 ]; then
    if [ ! -x "$SHARED_FINISHED" ]; then
        printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_FINISHED" >&2
        exit 2
    fi
    exec "$SHARED_FINISHED" "Claude Code" "Finished"
fi

exit 0
```

`home/dot_claude/hooks/executable_pre-tool-use.sh`

```bash
#!/bin/bash
# Claude Code PreToolUse adapter.
# Parses Claude's JSON payload and forwards to the shared preflight core.

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"
SHARED_CHECK_PREFLIGHT="$HOME/.agents/hooks/bin/check-preflight.sh"
SHARED_DANGER="$HOME/.agents/hooks/bin/agent-danger"

if [ ! -x "$SHARED_CHECK_PREFLIGHT" ]; then
    printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_CHECK_PREFLIGHT" >&2
    exit 2
fi

"$SHARED_CHECK_PREFLIGHT" "$TOOL_NAME" "$FILE_PATH" "$COMMAND"
STATUS=$?

if [ "$STATUS" -eq 2 ] && [ -x "$SHARED_DANGER" ]; then
    "$SHARED_DANGER" "Claude Code" "Dangerous command blocked" >/dev/null 2>&1 || true
fi

exit "$STATUS"
```

- [ ] **Step 4: Update the Gemini adapters**

Use these file contents:

`home/dot_gemini/hooks/executable_notification.sh`

```bash
#!/bin/bash
# Gemini attention notification adapter.

cat >/dev/null

SHARED_ATTENTION="$HOME/.agents/hooks/bin/agent-attention"

if [ ! -x "$SHARED_ATTENTION" ]; then
    printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_ATTENTION" >&2
    exit 2
fi

exec "$SHARED_ATTENTION" "Gemini" "Needs your attention"
```

`home/dot_gemini/hooks/executable_stop.sh`

```bash
#!/bin/bash
# Gemini completion notification adapter.

cat >/dev/null

SHARED_FINISHED="$HOME/.agents/hooks/bin/agent-finished"

if [ ! -x "$SHARED_FINISHED" ]; then
    printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_FINISHED" >&2
    exit 2
fi

exec "$SHARED_FINISHED" "Gemini" "Finished"
```

`home/dot_gemini/hooks/executable_pre-tool-use.sh`

```bash
#!/bin/bash
# Gemini PreToolUse adapter.

INPUT="$(cat)"
SHARED_CHECK_PREFLIGHT="$HOME/.agents/hooks/bin/check-preflight.sh"
SHARED_DANGER="$HOME/.agents/hooks/bin/agent-danger"

if [ ! -x "$SHARED_CHECK_PREFLIGHT" ]; then
    printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_CHECK_PREFLIGHT" >&2
    exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
    printf 'Blocked: missing jq for Gemini hook payload parsing.\n' >&2
    exit 2
fi

TOOL_NAME="$(printf '%s' "$INPUT" | jq -er '.tool_name' 2>/dev/null)" || {
    printf 'Blocked: invalid Gemini hook payload.\n' >&2
    exit 2
}

FILE_PATH=""
COMMAND=""
case "$TOOL_NAME" in
    Bash)
        COMMAND="$(printf '%s' "$INPUT" | jq -er '.tool_input.command' 2>/dev/null)" || {
            printf 'Blocked: invalid Gemini hook payload.\n' >&2
            exit 2
        }
        ;;
    Read|Edit|MultiEdit|Write)
        FILE_PATH="$(printf '%s' "$INPUT" | jq -er '.tool_input.file_path' 2>/dev/null)" || {
            printf 'Blocked: invalid Gemini hook payload.\n' >&2
            exit 2
        }
        ;;
    *)
        FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"
        COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)"
        ;;
esac

"$SHARED_CHECK_PREFLIGHT" "$TOOL_NAME" "$FILE_PATH" "$COMMAND"
STATUS=$?

if [ "$STATUS" -eq 2 ] && [ -x "$SHARED_DANGER" ]; then
    "$SHARED_DANGER" "Gemini" "Dangerous command blocked" >/dev/null 2>&1 || true
fi

exit "$STATUS"
```

- [ ] **Step 5: Run adapter tests**

Run:

```bash
bats tests/test_hooks.bats --filter "claude pre-tool-use emits danger signal on denied command|notification.sh:|stop.sh:"
bats tests/test_gemini_settings.bats --filter "gemini pre-tool-use emits danger signal on denied command|notification adapter delegates to shared notifier|stop adapter delegates to shared notifier"
```

Expected: `PASS`.

- [ ] **Step 6: Commit the Claude and Gemini adapter changes**

```bash
git add home/dot_claude/hooks/executable_notification.sh home/dot_claude/hooks/executable_stop.sh home/dot_claude/hooks/executable_pre-tool-use.sh home/dot_gemini/hooks/executable_notification.sh home/dot_gemini/hooks/executable_stop.sh home/dot_gemini/hooks/executable_pre-tool-use.sh tests/test_hooks.bats tests/test_gemini_settings.bats
git commit -m "feat: route claude and gemini hooks through agent signals"
```

---

### Task 3: Update Codex adapters while preserving Codex-specific hook contracts

**Files:**

- Modify: `home/dot_codex/hooks/executable_stop.sh`
- Modify: `home/dot_codex/hooks/executable_pre-tool-use.sh`
- Test: `tests/test_codex_config.bats`

- [ ] **Step 1: Write failing Codex adapter tests**

Update or add these tests in `tests/test_codex_config.bats`:

```bash
@test "stop adapter invokes shared finished signal when stop_hook_active is false" {
    mkdir -p "$TEST_HOME/.agents/hooks/bin"
    cat > "$TEST_HOME/.agents/hooks/bin/agent-finished" <<'EOF'
#!/bin/bash
printf '%s\n' "$*"
EOF
    chmod +x "$TEST_HOME/.agents/hooks/bin/agent-finished"

    run env HOME="$TEST_HOME" "$BASH_BIN" "$REPO_ROOT/home/dot_codex/hooks/executable_stop.sh" <<'EOF'
{"stop_hook_active":false}
EOF

    [ "$status" -eq 0 ]
    [ "$output" = "Codex Finished" ]
}

@test "pre-tool-use adapter emits danger signal before deny response" {
    mkdir -p "$TEST_HOME/.agents/hooks/bin"
    cat > "$TEST_HOME/.agents/hooks/bin/check-preflight.sh" <<'EOF'
#!/bin/bash
exit 2
EOF
    cat > "$TEST_HOME/.agents/hooks/bin/agent-danger" <<'EOF'
#!/bin/bash
printf '%s\n' "$*" >> "$HOME/danger.log"
EOF
    chmod +x "$TEST_HOME/.agents/hooks/bin/check-preflight.sh" "$TEST_HOME/.agents/hooks/bin/agent-danger"

    run env HOME="$TEST_HOME" "$BASH_BIN" "$REPO_ROOT/home/dot_codex/hooks/executable_pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}
EOF

    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
    grep -q "Codex" "$TEST_HOME/danger.log"
}
```

- [ ] **Step 2: Run the focused tests and confirm they fail**

Run:

```bash
bats tests/test_codex_config.bats --filter "stop adapter invokes shared finished signal when stop_hook_active is false|pre-tool-use adapter emits danger signal before deny response"
```

Expected: `FAIL` because Codex still targets the old shared notifier names.

- [ ] **Step 3: Update the Codex stop adapter**

Replace `home/dot_codex/hooks/executable_stop.sh` with:

```bash
#!/bin/bash
# Codex Stop adapter.
# Delegates completion notifications to the shared signal runtime.

INPUT="$(cat)"
SHARED_FINISHED="$HOME/.agents/hooks/bin/agent-finished"

if ! command -v jq >/dev/null 2>&1; then
    printf 'Stop hook blocked: missing jq for Codex payload parsing.\n' >&2
    exit 2
fi

STOP_HOOK_ACTIVE="$(printf '%s' "$INPUT" | jq -r '
    if has("stop_hook_active") then
        .stop_hook_active
    else
        false
    end
    | if type == "boolean" then tostring else error("invalid stop_hook_active") end
' 2>/dev/null)" || {
    printf 'Stop hook blocked: invalid Codex payload.\n' >&2
    exit 2
}

if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    printf '{"continue":true}\n'
    exit 0
fi

if [ ! -x "$SHARED_FINISHED" ]; then
    printf 'Stop hook blocked: missing shared notifier: %s\n' "$SHARED_FINISHED" >&2
    exit 2
fi

exec "$SHARED_FINISHED" "Codex" "Finished"
```

- [ ] **Step 4: Update the Codex PreToolUse adapter**

Replace `home/dot_codex/hooks/executable_pre-tool-use.sh` with:

```bash
#!/bin/bash
# Codex PreToolUse adapter.
# Restricts the shared preflight core to the Bash tool, which is the only
# practical Codex PreToolUse target in this dotfiles setup.

INPUT="$(cat)"
SHARED_CHECK_PREFLIGHT="$HOME/.agents/hooks/bin/check-preflight.sh"
SHARED_DANGER="$HOME/.agents/hooks/bin/agent-danger"

if [ ! -x "$SHARED_CHECK_PREFLIGHT" ]; then
    printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_CHECK_PREFLIGHT" >&2
    exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
    printf 'Blocked: missing jq for Codex hook payload parsing.\n' >&2
    exit 2
fi

TOOL_NAME="$(printf '%s' "$INPUT" | jq -er '.tool_name' 2>/dev/null)" || {
    printf 'Blocked: invalid Codex hook payload.\n' >&2
    exit 2
}

if [ -z "$TOOL_NAME" ]; then
    printf 'Blocked: invalid Codex hook payload.\n' >&2
    exit 2
fi

if [ "$TOOL_NAME" != "Bash" ]; then
    exit 0
fi

COMMAND="$(printf '%s' "$INPUT" | jq -er '.tool_input.command' 2>/dev/null)" || {
    printf 'Blocked: invalid Codex hook payload.\n' >&2
    exit 2
}

if [ -z "$COMMAND" ]; then
    printf 'Blocked: invalid Codex hook payload.\n' >&2
    exit 2
fi

"$SHARED_CHECK_PREFLIGHT" "$TOOL_NAME" "" "$COMMAND"
STATUS=$?

if [ "$STATUS" -eq 0 ]; then
    exit 0
fi

if [ "$STATUS" -eq 2 ]; then
    if [ -x "$SHARED_DANGER" ]; then
        "$SHARED_DANGER" "Codex" "Dangerous command blocked" >/dev/null 2>&1 || true
    fi
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked by shared preflight policy."}}\n'
    exit 0
fi

exit "$STATUS"
```

- [ ] **Step 5: Run Codex tests**

Run:

```bash
bats tests/test_codex_config.bats
```

Expected: `PASS`.

- [ ] **Step 6: Commit the Codex adapter changes**

```bash
git add home/dot_codex/hooks/executable_stop.sh home/dot_codex/hooks/executable_pre-tool-use.sh tests/test_codex_config.bats
git commit -m "feat: route codex hooks through agent signals"
```

---

### Task 4: Update docs, shared installation tests, and full verification

**Files:**

- Modify: `tests/test_hooks.bats`
- Modify: `tests/test_gemini_settings.bats`
- Modify: `docs/tools/gemini.md`
- Modify: `docs/superpowers/specs/2026-04-21-agent-hooks-unification-design.md`

- [ ] **Step 1: Update shared hook installation helpers in tests**

In `tests/test_hooks.bats` and `tests/test_gemini_settings.bats`, replace the old shared binary copies:

```bash
cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_notify-attention.sh" "$target_home/.agents/hooks/bin/notify-attention.sh"
cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_notify-finished.sh" "$target_home/.agents/hooks/bin/notify-finished.sh"
```

with:

```bash
cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-signal.sh" "$target_home/.agents/hooks/bin/agent-signal"
cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-attention.sh" "$target_home/.agents/hooks/bin/agent-attention"
cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-finished.sh" "$target_home/.agents/hooks/bin/agent-finished"
cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-danger.sh" "$target_home/.agents/hooks/bin/agent-danger"
```

Update the matching `chmod +x` blocks as well.

- [ ] **Step 2: Refresh docs to use signal terminology**

Update `docs/tools/gemini.md` table rows to:

```md
| `PreToolUse` | `~/.agents/hooks/bin/check-preflight.sh` を呼び出し、deny 時は `~/.agents/hooks/bin/agent-danger` で警告音を鳴らす |
| `Notification` | `~/.agents/hooks/bin/agent-attention` で注意喚起シグナルを送る |
| `Stop` | `~/.agents/hooks/bin/agent-finished` で完了シグナルを送る |
```

Update `docs/superpowers/specs/2026-04-21-agent-hooks-unification-design.md` file layout and notification policy sections so they reference `agent-attention`, `agent-finished`, and `agent-danger` instead of the old `notify-*` executables.

- [ ] **Step 3: Run full verification**

Run:

```bash
bats tests/test_hooks.bats
bats tests/test_gemini_settings.bats
bats tests/test_codex_config.bats
markdownlint-cli2 docs/tools/gemini.md docs/superpowers/specs/2026-04-21-agent-hooks-unification-design.md docs/superpowers/specs/2026-04-21-agent-notification-signals-design.md docs/superpowers/plans/2026-04-21-agent-notification-signals.md
shellcheck home/dot_agents/hooks/lib/executable_notify.sh home/dot_agents/hooks/bin/executable_agent-signal.sh home/dot_agents/hooks/bin/executable_agent-attention.sh home/dot_agents/hooks/bin/executable_agent-finished.sh home/dot_agents/hooks/bin/executable_agent-danger.sh home/dot_claude/hooks/executable_notification.sh home/dot_claude/hooks/executable_stop.sh home/dot_claude/hooks/executable_pre-tool-use.sh home/dot_gemini/hooks/executable_notification.sh home/dot_gemini/hooks/executable_stop.sh home/dot_gemini/hooks/executable_pre-tool-use.sh home/dot_codex/hooks/executable_stop.sh home/dot_codex/hooks/executable_pre-tool-use.sh
```

Expected:

- all `bats` suites pass
- `markdownlint-cli2` reports `0 error(s)`
- `shellcheck` exits `0`

- [ ] **Step 4: Commit docs and final verification updates**

```bash
git add tests/test_hooks.bats tests/test_gemini_settings.bats docs/tools/gemini.md docs/superpowers/specs/2026-04-21-agent-hooks-unification-design.md docs/superpowers/plans/2026-04-21-agent-notification-signals.md
git commit -m "docs: update agent notification signal references"
```

- [ ] **Step 5: Final repository status check**

Run:

```bash
git status --short
git log --oneline -n 4
```

Expected:

- working tree is clean
- the most recent commits correspond to the signal runtime, adapter updates, Codex updates, and docs/test refresh
