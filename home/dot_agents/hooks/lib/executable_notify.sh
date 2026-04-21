#!/bin/bash
# Shared notification library for agent hooks.
# Usage: source this file, then call send_notification TITLE MESSAGE.

NOTIFY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$NOTIFY_LIB_DIR/platform.sh"

print_notice() {
    local title="$1"
    local message="$2"
    local notify_error="${3:-}"

    printf '[NOTICE] %s: %s\n' "$title" "$message" >&2
    if [ -n "$notify_error" ]; then
        printf '[NOTICE] desktop notification failed: %s\n' "$notify_error" >&2
    fi
}

run_notification_command() {
    local title="$1"
    local message="$2"
    shift 2

    local notify_error

    if ! notify_error="$("$@" 2>&1)"; then
        print_notice "$title" "$message" "$notify_error"
    fi
}

# send_notification TITLE MESSAGE
# Sends a desktop notification using the platform-appropriate command.
# Falls back to stderr when no notification command is available.
send_notification() {
    local title="$1"
    local message="$2"

    case "$PLATFORM" in
        macos)
            run_notification_command \
                "$title" \
                "$message" \
                osascript -e "display notification \"$message\" with title \"$title\""
            ;;
        wsl|linux)
            if command -v notify-send >/dev/null 2>&1; then
                run_notification_command "$title" "$message" notify-send "$title" "$message"
            else
                print_notice "$title" "$message"
            fi
            ;;
        *)
            print_notice "$title" "$message"
            ;;
    esac

    return 0
}
