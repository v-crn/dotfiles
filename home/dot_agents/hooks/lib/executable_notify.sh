#!/bin/bash
# Shared notification and signal runtime for agent hooks.
# Usage:
#   source this file, then call send_notification TITLE MESSAGE
#   or emit_agent_signal EVENT AGENT [MESSAGE]

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

run_quiet_command() {
    "$@" >/dev/null 2>&1
}

run_macos_notification_command() {
    local title="$1"
    local message="$2"
    local script

    printf -v script '%s\n%s\n%s' \
        'set agentTitle to system attribute "AGENT_SIGNAL_TITLE"' \
        'set agentMessage to system attribute "AGENT_SIGNAL_MESSAGE"' \
        'display notification agentMessage with title agentTitle'
    AGENT_SIGNAL_TITLE="$title" AGENT_SIGNAL_MESSAGE="$message" run_notification_command "$title" "$message" osascript -e "$script"
}

# send_notification TITLE MESSAGE
# Sends a desktop notification using the platform-appropriate command.
# Falls back to stderr when no notification command is available.
send_notification() {
    local title="$1"
    local message="$2"

    case "$PLATFORM" in
        macos)
            run_macos_notification_command "$title" "$message"
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

_agent_signal_tmpdir() {
    printf '%s\n' "${TMPDIR:-/tmp}"
}

_agent_signal_session_id() {
    if [ -n "${XDG_SESSION_ID:-}" ]; then
        printf '%s\n' "$XDG_SESSION_ID"
        return 0
    fi

    local session_id
    session_id="$(ps -o sid= -p "$$" 2>/dev/null | tr -d '[:space:]')"
    if [ -n "$session_id" ]; then
        printf '%s\n' "$session_id"
        return 0
    fi

    printf '%s\n' "$$"
}

_agent_signal_warn_marker() {
    local session_id
    session_id="$(_agent_signal_session_id)"
    printf '%s/%s\n' "$(_agent_signal_tmpdir)" "agent-signal-${USER:-unknown}-${session_id}.warned"
}

warn_agent_signal_once() {
    local marker
    marker="$(_agent_signal_warn_marker)"
    if [ -e "$marker" ]; then
        return 0
    fi

    : > "$marker"
    printf '%s\n' "$@" >&2
}

resolve_signal_policy() {
    case "$PLATFORM" in
        wsl) printf 'sound\n' ;;
        linux|macos) printf 'toast+sound\n' ;;
        *) printf 'sound\n' ;;
    esac
}

linux_sound_name() {
    case "$1" in
        attention) printf 'message-new-instant\n' ;;
        finished) printf 'complete\n' ;;
        danger) printf 'dialog-warning\n' ;;
        *) printf 'dialog-information\n' ;;
    esac
}

macos_sound_name() {
    case "$1" in
        attention) printf 'Glass\n' ;;
        finished) printf 'Hero\n' ;;
        danger) printf 'Basso\n' ;;
        *) printf 'Glass\n' ;;
    esac
}

run_wsl_sound() {
    case "$1" in
        attention)
            run_quiet_command play -n synth 0.22 sine 784 vol 0.12 fade q 0.01 0.22 0.06
            ;;
        finished)
            run_quiet_command play -n synth 0.18 sine 740 vol 0.12 fade q 0.01 0.18 0.05 || return $?
            sleep 0.3
            run_quiet_command play -n synth 0.18 sine 988 vol 0.10 fade q 0.01 0.18 0.05
            ;;
        danger)
            run_quiet_command play -n synth 0.28 triangle 660-990 vol 0.11 fade q 0.01 0.28 0.08
            ;;
        *)
            return 1
            ;;
    esac
}

run_toast_with_sound() {
    local event="$1"
    local agent="$2"
    local message="$3"

    case "$PLATFORM" in
        linux)
            if command -v notify-send >/dev/null 2>&1; then
                run_quiet_command notify-send --hint="string:sound-name:$(linux_sound_name "$event")" "$agent" "$message"
                return $?
            fi
            return 1
            ;;
        macos)
            if command -v osascript >/dev/null 2>&1; then
                local script
                local sound_name
                sound_name="$(macos_sound_name "$event")"
                printf -v script '%s\n%s\n%s sound name "%s"' \
                    'set agentTitle to system attribute "AGENT_SIGNAL_TITLE"' \
                    'set agentMessage to system attribute "AGENT_SIGNAL_MESSAGE"' \
                    'display notification agentMessage with title agentTitle' \
                    "$sound_name"
                AGENT_SIGNAL_TITLE="$agent" AGENT_SIGNAL_MESSAGE="$message" run_quiet_command osascript -e "$script"
                return $?
            fi
            return 1
            ;;
    esac

    return 1
}

run_toast_only() {
    local agent="$1"
    local message="$2"

    case "$PLATFORM" in
        linux)
            if command -v notify-send >/dev/null 2>&1; then
                run_quiet_command notify-send "$agent" "$message"
                return $?
            fi
            return 1
            ;;
        macos)
            if command -v osascript >/dev/null 2>&1; then
                local script
                printf -v script '%s\n%s\n%s' \
                    'set agentTitle to system attribute "AGENT_SIGNAL_TITLE"' \
                    'set agentMessage to system attribute "AGENT_SIGNAL_MESSAGE"' \
                    'display notification agentMessage with title agentTitle'
                AGENT_SIGNAL_TITLE="$agent" AGENT_SIGNAL_MESSAGE="$message" run_quiet_command osascript -e "$script"
                return $?
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

run_sound_only() {
    local event="$1"

    case "$PLATFORM" in
        wsl)
            command -v play >/dev/null 2>&1 || return 1
            run_wsl_sound "$event"
            ;;
        linux)
            command -v play >/dev/null 2>&1 || return 1
            case "$event" in
                attention) run_quiet_command play -n synth 0.16 sine 880 vol 0.10 fade q 0.01 0.16 0.05; return $? ;;
                finished) run_quiet_command play -n synth 0.14 sine 740 vol 0.10 fade q 0.01 0.14 0.04 || return $? ; sleep 0.2 ; run_quiet_command play -n synth 0.14 sine 988 vol 0.08 fade q 0.01 0.14 0.04; return $? ;;
                danger) run_quiet_command play -n synth 0.20 triangle 660-990 vol 0.10 fade q 0.01 0.20 0.06; return $? ;;
                *) return 1 ;;
            esac
            ;;
        macos)
            if command -v afplay >/dev/null 2>&1; then
                if run_quiet_command afplay "/System/Library/Sounds/$(macos_sound_name "$event").aiff"; then
                    return 0
                fi
            fi
            if command -v osascript >/dev/null 2>&1; then
                run_quiet_command osascript -e "beep"
                return $?
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

warn_missing_channels() {
    local event="$1"
    local policy="$2"
    local requested_channels="$3"
    local toast_available="$4"
    local sound_available="$5"
    local toast_checked="$6"
    local sound_checked="$7"
    local toast_impl="$8"
    local sound_impl="$9"

    warn_agent_signal_once \
        "[agent-signal] requested channels unavailable" \
        "platform=$PLATFORM event=$event policy=$policy" \
        "requested channels: $requested_channels" \
        "available implementations: toast=$toast_impl sound=$sound_impl" \
        "toast available: $toast_available" \
        "sound available: $sound_available" \
        "toast checked: $toast_checked" \
        "sound checked: $sound_checked"
}

resolve_requested_channels() {
    case "$1" in
        toast) printf 'toast\n' ;;
        sound) printf 'sound\n' ;;
        toast+sound) printf 'toast+sound\n' ;;
        *) printf '%s\n' "$1" ;;
    esac
}

default_signal_message() {
    case "$1" in
        attention) printf 'Needs your attention\n' ;;
        finished) printf 'Finished\n' ;;
        danger) printf 'Dangerous command blocked\n' ;;
        *) printf 'Signal\n' ;;
    esac
}

emit_agent_signal() {
    local event="$1"
    local agent="$2"
    local message="${3:-$(default_signal_message "$event")}"
    local policy requested_channels toast_available sound_available toast_impl sound_impl

    policy="$(resolve_signal_policy "$event")"
    requested_channels="$(resolve_requested_channels "$policy")"

    case "$PLATFORM" in
        linux)
            toast_available="none"
            toast_impl="none"
            if command -v notify-send >/dev/null 2>&1; then
                toast_available="configured"
                toast_impl="notify-send"
            fi
            sound_available="none"
            sound_impl="none"
            if command -v play >/dev/null 2>&1; then
                sound_available="configured"
                sound_impl="play"
            fi
            ;;
        macos)
            toast_available="none"
            toast_impl="none"
            if command -v osascript >/dev/null 2>&1; then
                toast_available="configured"
                toast_impl="osascript"
            fi
            sound_available="none"
            sound_impl="none"
            if command -v afplay >/dev/null 2>&1; then
                sound_available="configured"
                sound_impl="afplay"
            elif command -v osascript >/dev/null 2>&1; then
                sound_available="configured"
                sound_impl="osascript"
            fi
            ;;
        wsl)
            toast_available="none"
            sound_available="none"
            toast_impl="none"
            sound_impl="none"
            if command -v play >/dev/null 2>&1; then
                sound_available="configured"
                sound_impl="play"
            fi
            ;;
        *)
            toast_available="none"
            sound_available="none"
            toast_impl="none"
            sound_impl="none"
            ;;
    esac

    case "$policy" in
        toast)
            if run_toast_only "$agent" "$message"; then
                return 0
            fi
            ;;
        sound)
            if run_sound_only "$event"; then
                return 0
            fi
            ;;
        toast+sound)
            if run_toast_with_sound "$event" "$agent" "$message"; then
                return 0
            fi

            local toast_ok=1
            local sound_ok=1

            if run_toast_only "$agent" "$message"; then
                toast_ok=0
            fi
            if run_sound_only "$event"; then
                sound_ok=0
            fi

            if [ "$toast_ok" -eq 0 ] || [ "$sound_ok" -eq 0 ]; then
                warn_missing_channels \
                    "$event" \
                    "$policy" \
                    "$requested_channels" \
                    "$toast_available" \
                    "$sound_available" \
                    "notify-send osascript" \
                    "play afplay osascript" \
                    "$toast_impl" \
                    "$sound_impl"
                return 0
            fi
            ;;
    esac

    warn_missing_channels \
        "$event" \
        "$policy" \
        "$requested_channels" \
        "$toast_available" \
        "$sound_available" \
        "notify-send osascript" \
        "play afplay osascript" \
        "$toast_impl" \
        "$sound_impl"
    return 0
}
