#!/bin/bash
# Codex PreToolUse adapter.
# Restricts the shared preflight core to the Bash tool, which is the only
# practical Codex PreToolUse target in this dotfiles setup.

INPUT="$(cat)"
SHARED_CHECK_PREFLIGHT="$HOME/.agents/hooks/bin/check-preflight.sh"

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
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Blocked by shared preflight policy."}}\n'
    exit 0
fi

exit "$STATUS"
