#!/bin/bash
# Codex Stop adapter.
# Delegates completion notifications to the shared notifier.

INPUT="$(cat)"
SHARED_FINISHED="$HOME/.agents/hooks/bin/notify-finished.sh"

if ! command -v jq >/dev/null 2>&1; then
    printf 'Stop hook blocked: missing jq for Codex payload parsing.\n' >&2
    exit 2
fi

STOP_HOOK_ACTIVE="$(printf '%s' "$INPUT" | jq -r '
    if has("stop_hook_active") then
        .stop_hook_active
    else
        false
    end
    | if type == "boolean" then tostring else error("invalid stop_hook_active") end
' 2>/dev/null)" || {
    printf 'Stop hook blocked: invalid Codex payload.\n' >&2
    exit 2
}

if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
    printf '{"continue":true}\n'
    exit 0
fi

if [ ! -x "$SHARED_FINISHED" ]; then
    printf 'Stop hook blocked: missing shared notifier: %s\n' "$SHARED_FINISHED" >&2
    exit 2
fi

exec "$SHARED_FINISHED" "Codex" "Finished"
