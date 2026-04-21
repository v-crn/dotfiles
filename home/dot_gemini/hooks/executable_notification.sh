#!/bin/bash
# Gemini attention notification adapter.

cat >/dev/null

SHARED_ATTENTION="$HOME/.agents/hooks/bin/notify-attention.sh"

if [ ! -x "$SHARED_ATTENTION" ]; then
    printf 'Blocked: missing shared hook binary: %s\n' "$SHARED_ATTENTION" >&2
    exit 2
fi

exec "$SHARED_ATTENTION" "Gemini" "Needs your attention"
