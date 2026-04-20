#!/bin/bash
# Notification event hook for Claude Code.
# Fires when Claude needs attention (permission prompt, idle, etc.).
# shellcheck disable=SC1090,SC1091
. ~/.agents/hooks/lib/notify.sh

cat > /dev/null

send_notification "Claude Code" "Needs your attention"
