#!/bin/bash
# Codex PreToolUse adapter.
# Restricts the shared preflight core to the Bash tool, which is the only
# practical Codex PreToolUse target in this dotfiles setup.

INPUT="$(cat)"
SHARED_CHECK_PREFLIGHT="$HOME/.agents/hooks/bin/check-preflight.sh"
SHARED_DANGER="$HOME/.agents/hooks/bin/agent-danger.sh"

should_emit_danger_signal() {
    case "$1" in
        *'Blocked: destructive rm detected.'*|*'Blocked: destructive SQL command detected.'*|*'Blocked: reading sensitive env file via shell:'*)
            return 0
            ;;
    esac

    return 1
}

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

preflight_stderr_file="$(mktemp "${TMPDIR:-/tmp}/codex-preflight.XXXXXX")" || exit 2

if "$SHARED_CHECK_PREFLIGHT" "$TOOL_NAME" "" "$COMMAND" 2>"$preflight_stderr_file"; then
    STATUS=0
else
    STATUS=$?
fi

preflight_output="$(cat "$preflight_stderr_file")"
rm -f "$preflight_stderr_file"

if [ -n "$preflight_output" ]; then
    printf '%s\n' "$preflight_output" >&2
fi

if [ "$STATUS" -eq 2 ] && [ -x "$SHARED_DANGER" ] && should_emit_danger_signal "$preflight_output"; then
    "$SHARED_DANGER" "Codex" "Dangerous command blocked"
fi

if [ "$STATUS" -eq 0 ]; then
    exit 0
fi

if [ "$STATUS" -eq 2 ]; then
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked by shared preflight policy."}}\n'
    exit 0
fi

exit "$STATUS"
