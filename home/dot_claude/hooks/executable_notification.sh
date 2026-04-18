#!/bin/bash
# Notification event hook for Claude Code.
# Fires when Claude needs attention (permission prompt, idle, etc.).

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$HOOK_DIR/lib/notify.sh"

# Consume stdin (Claude Code pipes a JSON payload; we don't need it here)
cat > /dev/null

send_notification "Claude Code" "Needs your attention"
