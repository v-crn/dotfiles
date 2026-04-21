#!/bin/bash
# Claude Code PreToolUse adapter.
# Parses Claude's JSON payload and forwards to the shared preflight core.

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"
FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"
SHARED_CHECK_PREFLIGHT="$HOME/.agents/hooks/bin/check-preflight.sh"

if [ ! -x "$SHARED_CHECK_PREFLIGHT" ]; then
    printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_CHECK_PREFLIGHT" >&2
    exit 2
fi

exec "$SHARED_CHECK_PREFLIGHT" "$TOOL_NAME" "$FILE_PATH" "$COMMAND"
