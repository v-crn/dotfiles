#!/bin/bash
# Claude Code stop adapter.
# Keeps Claude-specific timing and loop-guard behavior, then delegates to the shared finished signal.

INPUT="$(cat)"
SHARED_FINISHED="$HOME/.agents/hooks/bin/agent-finished.sh"

# Guard: stop_hook_active=true means we're already in a stop hook loop — exit early
if [ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = "true" ]; then
    exit 0
fi

SESSION_ID="$(printf '%s' "$INPUT" | jq -r '.session_id // empty')"
if [ -z "$SESSION_ID" ]; then
    exit 0
fi
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
    if [ ! -x "$SHARED_FINISHED" ]; then
        printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_FINISHED" >&2
        exit 2
    fi
    exec "$SHARED_FINISHED" "Claude Code" "Finished"
fi

exit 0
