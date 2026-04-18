#!/bin/bash
# Notification library for Claude Code hooks.
# Usage: source this file, then call send_notification TITLE MESSAGE.

NOTIFY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$NOTIFY_LIB_DIR/platform.sh"

# send_notification TITLE MESSAGE
# Sends a desktop notification using the platform-appropriate command.
# Falls back to stderr when no notification command is available.
send_notification() {
    local title="$1"
    local message="$2"

    case "$PLATFORM" in
        macos)
            osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null
            ;;
        wsl|linux)
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "$title" "$message"
            else
                printf '[NOTICE] %s: %s\n' "$title" "$message" >&2
            fi
            ;;
        *)
            printf '[NOTICE] %s: %s\n' "$title" "$message" >&2
            ;;
    esac
}
