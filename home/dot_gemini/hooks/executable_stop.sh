#!/bin/bash
# Gemini completion notification adapter.

cat >/dev/null

SHARED_FINISHED="$HOME/.agents/hooks/bin/notify-finished.sh"

if [ ! -x "$SHARED_FINISHED" ]; then
    printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_FINISHED" >&2
    exit 2
fi

exec "$SHARED_FINISHED" "Gemini" "Finished"
