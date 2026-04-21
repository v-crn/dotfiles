#!/bin/bash
# Gemini PreToolUse adapter.

INPUT="$(cat)"
SHARED_CHECK_PREFLIGHT="$HOME/.agents/hooks/bin/check-preflight.sh"

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

exec "$SHARED_CHECK_PREFLIGHT" "$TOOL_NAME" "$FILE_PATH" "$COMMAND"
