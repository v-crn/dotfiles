#!/bin/bash
# Claude Code PreToolUse adapter.
# Parses Claude's JSON payload and forwards to the shared preflight core.

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"
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

preflight_stderr_file="$(mktemp "${TMPDIR:-/tmp}/claude-preflight.XXXXXX")" || exit 2

if "$SHARED_CHECK_PREFLIGHT" "$TOOL_NAME" "$FILE_PATH" "$COMMAND" 2>"$preflight_stderr_file"; then
    STATUS=0
else
    STATUS=$?
fi

preflight_output="$(cat "$preflight_stderr_file")"
rm -f "$preflight_stderr_file"

if [ -n "$preflight_output" ]; then
    printf '%s\n' "$preflight_output" >&2
fi

if [ "$STATUS" -eq 2 ] && [ "$TOOL_NAME" = "Bash" ] && [ -x "$SHARED_DANGER" ]; then
    if should_emit_danger_signal "$preflight_output"; then
        "$SHARED_DANGER" "Claude Code" "Dangerous command blocked"
    fi
fi

exit "$STATUS"
