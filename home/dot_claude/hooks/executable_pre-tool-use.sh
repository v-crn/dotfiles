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

# is_sensitive_env_file PATH_OR_BASENAME
# Returns 0 (block) if the file is a sensitive .env file.
# Matches exactly ".env" or ".env.<something>" (dot-separated).
# Files like ".envrc" (no dot separator) are NOT matched and pass through.
# A matched file is sensitive when none of its dot-separated segments
# is a safe keyword: example template sample default dist schema
is_sensitive_env_file() {
    local base
    base="$(basename "$1")"
    case "$base" in
        .env | .env.*) ;;
        *) return 1 ;;
    esac
    local stripped="${base#.}"
    local old_IFS="$IFS"
    IFS='.'
    # shellcheck disable=SC2086
    set -- $stripped
    IFS="$old_IFS"
    for segment; do
        case "$segment" in
            example|template|sample|default|dist|schema)
                return 1  # safe keyword found — allow
                ;;
        esac
    done
    return 0  # no safe keyword — block
}

# ---------------------------------------------------------------------------
# File-based tools: Read, Edit, Write
# ---------------------------------------------------------------------------

case "$TOOL_NAME" in
    Read|Edit|MultiEdit|Write)
        FILE_PATH="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')"
        if [ -n "$FILE_PATH" ] && is_sensitive_env_file "$FILE_PATH"; then
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

    # Block: destructive rm targeting root, home, or filesystem root glob
    # Match: rm -rf / (end), rm -rf / (space after), rm -rf /*, rm -rf ~
    case "$COMMAND" in
        *"rm -rf ~"* | *"rm -rf /*"* | *"rm -rf ."*)
            printf 'Blocked: destructive rm detected. Command: %s\n' "$COMMAND" >&2
            exit 2
            ;;
    esac
    # Block rm -rf / only when / is the exact target (end of string or followed by space/;)
    if printf '%s' "$COMMAND" | grep -qE 'rm[[:space:]]+-rf[[:space:]]+/([[:space:];]|$)'; then
        printf 'Blocked: destructive rm detected. Command: %s\n' "$COMMAND" >&2
        exit 2
    fi

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
        cat\ * | less\ * | more\ * | head\ * | tail\ * | grep\ * | source\ * | .\ *)
            # Extract .env* token(s) from the command
            ENV_REF="$(printf '%s' "$COMMAND" | grep -oE '\.env[a-zA-Z0-9._-]*' | head -1)"
            if [ -n "$ENV_REF" ] && is_sensitive_env_file "$ENV_REF"; then
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
