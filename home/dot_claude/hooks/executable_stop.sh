#!/bin/bash
# Claude Code stop adapter.
# Delegates to the shared finished signal on every stop event.

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

if [ ! -x "$SHARED_FINISHED" ]; then
    printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_FINISHED" >&2
    exit 2
fi

exec "$SHARED_FINISHED" "Claude Code" "Finished"
