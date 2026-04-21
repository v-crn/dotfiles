#!/usr/bin/env bats
# Tests for Claude Code hook scripts

REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
PLATFORM_SH="$REPO_ROOT/home/dot_agents/hooks/lib/executable_platform.sh"
HOOKS_DIR="$REPO_ROOT/home/dot_claude/hooks"
CLAUDE_PRE_TOOL_USE_SH="$HOOKS_DIR/executable_pre-tool-use.sh"
CLAUDE_NOTIFICATION_SH="$HOOKS_DIR/executable_notification.sh"
CLAUDE_STOP_SH="$HOOKS_DIR/executable_stop.sh"

# ---------------------------------------------------------------------------
# lib/platform.sh
# ---------------------------------------------------------------------------

@test "platform.sh: exists and is executable" {
    [ -f "$PLATFORM_SH" ]
}

@test "platform.sh: detects macOS when uname returns Darwin" {
    run bash -c "uname() { echo Darwin; }; export -f uname; unset WSL_DISTRO_NAME; . '$PLATFORM_SH'; echo \$PLATFORM"
    [ "$output" = "macos" ]
}

@test "platform.sh: detects wsl when WSL_DISTRO_NAME is set" {
    run bash -c "WSL_DISTRO_NAME=Ubuntu . '$PLATFORM_SH'; echo \$PLATFORM"
    [ "$output" = "wsl" ]
}

@test "platform.sh: detects wsl from kernel osrelease when WSL env is absent" {
    run bash -c '
        uname() { echo Linux; }
        cat() {
            if [ "$1" = "/proc/sys/kernel/osrelease" ]; then
                echo "6.6.87.2-microsoft-standard-WSL2"
            else
                command cat "$@"
            fi
        }
        export -f uname cat
        unset WSL_DISTRO_NAME
        . "'"$PLATFORM_SH"'"
        echo "$PLATFORM"
    '
    [ "$output" = "wsl" ]
}

@test "platform.sh: detects wsl from proc version when osrelease is unavailable" {
    run bash -c '
        uname() { echo Linux; }
        cat() {
            if [ "$1" = "/proc/sys/kernel/osrelease" ]; then
                return 1
            fi
            if [ "$1" = "/proc/version" ]; then
                echo "Linux version 6.6.87.2-microsoft-standard-WSL2"
            else
                command cat "$@"
            fi
        }
        export -f uname cat
        unset WSL_DISTRO_NAME
        . "'"$PLATFORM_SH"'"
        echo "$PLATFORM"
    '
    [ "$output" = "wsl" ]
}

@test "platform.sh: returns linux on plain Linux without WSL" {
    run bash -c '
        uname() { echo Linux; }
        cat() {
            if [ "$1" = "/proc/sys/kernel/osrelease" ]; then
                echo "6.1.0-generic"
            elif [ "$1" = "/proc/version" ]; then
                echo "Linux version 6.1.0-generic"
            else
                command cat "$@"
            fi
        }
        export -f uname cat
        unset WSL_DISTRO_NAME
        . "'"$PLATFORM_SH"'"
        echo "$PLATFORM"
    '
    [ "$output" = "linux" ]
}

@test "platform.sh: returns unknown on unrecognized uname output" {
    run bash -c "uname() { echo SunOS; }; export -f uname; unset WSL_DISTRO_NAME; . '$PLATFORM_SH'; echo \$PLATFORM"
    [ "$output" = "unknown" ]
}

NOTIFY_SH="$HOME/.agents/hooks/lib/notify.sh"
ENV_POLICY_SH="$REPO_ROOT/home/dot_agents/hooks/lib/executable_env_policy.sh"
BASH_POLICY_SH="$REPO_ROOT/home/dot_agents/hooks/lib/executable_bash_policy.sh"
CHECK_PREFLIGHT_SOURCE_SH="$REPO_ROOT/home/dot_agents/hooks/bin/executable_check-preflight.sh"
install_shared_hooks_home() {
    local target_home="$1"

    mkdir -p "$target_home/.agents/hooks/lib" "$target_home/.agents/hooks/bin"
    cp "$REPO_ROOT/home/dot_agents/hooks/lib/executable_notify.sh" "$target_home/.agents/hooks/lib/notify.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/lib/executable_platform.sh" "$target_home/.agents/hooks/lib/platform.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/lib/executable_env_policy.sh" "$target_home/.agents/hooks/lib/env_policy.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/lib/executable_bash_policy.sh" "$target_home/.agents/hooks/lib/bash_policy.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_check-preflight.sh" "$target_home/.agents/hooks/bin/check-preflight.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-signal.sh" "$target_home/.agents/hooks/bin/agent-signal.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-attention.sh" "$target_home/.agents/hooks/bin/agent-attention.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-finished.sh" "$target_home/.agents/hooks/bin/agent-finished.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-danger.sh" "$target_home/.agents/hooks/bin/agent-danger.sh"
    chmod +x \
        "$target_home/.agents/hooks/lib/notify.sh" \
        "$target_home/.agents/hooks/lib/platform.sh" \
        "$target_home/.agents/hooks/lib/env_policy.sh" \
        "$target_home/.agents/hooks/lib/bash_policy.sh" \
        "$target_home/.agents/hooks/bin/check-preflight.sh" \
        "$target_home/.agents/hooks/bin/agent-signal.sh" \
        "$target_home/.agents/hooks/bin/agent-attention.sh" \
        "$target_home/.agents/hooks/bin/agent-finished.sh" \
        "$target_home/.agents/hooks/bin/agent-danger.sh"
}

install_signal_hooks_home() {
    local target_home="$1"

    mkdir -p "$target_home/.agents/hooks/lib" "$target_home/.agents/hooks/bin"
    cp "$REPO_ROOT/home/dot_agents/hooks/lib/executable_notify.sh" "$target_home/.agents/hooks/lib/notify.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/lib/executable_platform.sh" "$target_home/.agents/hooks/lib/platform.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-signal.sh" "$target_home/.agents/hooks/bin/agent-signal.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-attention.sh" "$target_home/.agents/hooks/bin/agent-attention.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-finished.sh" "$target_home/.agents/hooks/bin/agent-finished.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/bin/executable_agent-danger.sh" "$target_home/.agents/hooks/bin/agent-danger.sh"
    chmod +x \
        "$target_home/.agents/hooks/lib/notify.sh" \
        "$target_home/.agents/hooks/lib/platform.sh" \
        "$target_home/.agents/hooks/bin/agent-signal.sh" \
        "$target_home/.agents/hooks/bin/agent-attention.sh" \
        "$target_home/.agents/hooks/bin/agent-finished.sh" \
        "$target_home/.agents/hooks/bin/agent-danger.sh"
}

setup_shared_hooks_home() {
    SHARED_HOOKS_HOME="$(mktemp -d)"
    install_shared_hooks_home "$SHARED_HOOKS_HOME"
}

setup_signal_hooks_home() {
    SIGNAL_HOOKS_HOME="$(mktemp -d)"
    install_signal_hooks_home "$SIGNAL_HOOKS_HOME"
}

teardown_shared_hooks_home() {
    rm -rf "$SHARED_HOOKS_HOME"
}

teardown_signal_hooks_home() {
    rm -rf "$SIGNAL_HOOKS_HOME"
}

setup_bash_policy_home() {
    BASH_POLICY_HOME="$(mktemp -d)"
    mkdir -p "$BASH_POLICY_HOME/.agents/hooks/lib"
    cp "$REPO_ROOT/home/dot_agents/hooks/lib/executable_bash_policy.sh" "$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/lib/executable_bash_policy.sh" "$BASH_POLICY_HOME/.agents/hooks/lib/executable_bash_policy.sh"
    chmod +x \
        "$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh" \
        "$BASH_POLICY_HOME/.agents/hooks/lib/executable_bash_policy.sh"
}

setup_bash_policy_home_with_env() {
    setup_bash_policy_home
    cp "$REPO_ROOT/home/dot_agents/hooks/lib/executable_env_policy.sh" "$BASH_POLICY_HOME/.agents/hooks/lib/env_policy.sh"
    cp "$REPO_ROOT/home/dot_agents/hooks/lib/executable_env_policy.sh" "$BASH_POLICY_HOME/.agents/hooks/lib/executable_env_policy.sh"
    chmod +x \
        "$BASH_POLICY_HOME/.agents/hooks/lib/env_policy.sh" \
        "$BASH_POLICY_HOME/.agents/hooks/lib/executable_env_policy.sh"
}

teardown_bash_policy_home() {
    rm -rf "$BASH_POLICY_HOME"
}

# ---------------------------------------------------------------------------
# lib/notify.sh
# ---------------------------------------------------------------------------

@test "notify.sh: exists and is executable" {
    [ -f "$NOTIFY_SH" ]
    [ -x "$NOTIFY_SH" ]
}

@test "notify.sh: calls notify-send on linux/wsl when available" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    touch "$CALLS"
    # Create mock notify-send that logs arguments
    cat > "$MOCK_DIR/notify-send" << EOFMOCK
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOFMOCK
    chmod +x "$MOCK_DIR/notify-send"

    run bash -c "
        export PATH=\"$MOCK_DIR:\$PATH\"
        export WSL_DISTRO_NAME=Ubuntu
        . '$NOTIFY_SH'
        send_notification 'TestTitle' 'TestMessage'
    "
    [ "$status" -eq 0 ]
    [ -f "$CALLS" ]
    grep -q "TestTitle" "$CALLS"
    grep -q "TestMessage" "$CALLS"
    rm -rf "$MOCK_DIR"
}

@test "notify.sh: falls back to stderr when notify-send is absent" {
    # Remove notify-send from PATH by using an empty dir
    EMPTY_DIR="$(mktemp -d)"
    run bash -c "
        export PATH='$EMPTY_DIR'
        export WSL_DISTRO_NAME=Ubuntu
        . '$NOTIFY_SH'
        send_notification 'FallbackTitle' 'FallbackMsg'
    "
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "\[NOTICE\]"
    rm -rf "$EMPTY_DIR"
}

@test "notify.sh: falls back to stderr when notify-send fails" {
    setup_shared_hooks_home
    MOCK_DIR="$(mktemp -d)"
    cat > "$MOCK_DIR/notify-send" <<'EOFMOCK'
#!/bin/bash
echo "dbus unavailable" >&2
exit 1
EOFMOCK
    chmod +x "$MOCK_DIR/notify-send"

    run env HOME="$SHARED_HOOKS_HOME" bash -c "
        export PATH='$MOCK_DIR:\$PATH'
        export WSL_DISTRO_NAME=Ubuntu
        . '$SHARED_HOOKS_HOME/.agents/hooks/lib/notify.sh'
        output=\$(send_notification 'FallbackTitle' 'FallbackMsg' 2>&1)
        printf '%s\n' \"\$output\"
    "
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "\[NOTICE\] FallbackTitle: FallbackMsg"
    rm -rf "$MOCK_DIR"
    teardown_shared_hooks_home
}

@test "notify.sh: falls back to stderr on unknown platform" {
    EMPTY_DIR="$(mktemp -d)"
    run bash -c "
        export PATH='$EMPTY_DIR'
        unset WSL_DISTRO_NAME
        # Override uname to return something unknown
        uname() { echo 'SunOS'; }
        export -f uname
        . '$NOTIFY_SH'
        send_notification 'Title' 'Msg'
    "
    [ "$status" -eq 0 ]
    echo "$output" | grep -q "\[NOTICE\]"
    rm -rf "$EMPTY_DIR"
}

@test "notify.sh: macos send_notification handles multiline title and message" {
    setup_signal_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    TITLE_CAPTURE="$MOCK_DIR/title.capture"
    MESSAGE_CAPTURE="$MOCK_DIR/message.capture"
    touch "$CALLS"
    ln -s "$(command -v dirname)" "$MOCK_DIR/dirname"
    cat > "$MOCK_DIR/uname" <<'EOFMOCK'
#!/bin/bash
printf 'Darwin\n'
EOFMOCK
    chmod +x "$MOCK_DIR/uname"
    cat > "$MOCK_DIR/osascript" <<EOFMOCK
#!/bin/bash
printf '%s' "\$AGENT_SIGNAL_TITLE" > "$TITLE_CAPTURE"
printf '%s' "\$AGENT_SIGNAL_MESSAGE" > "$MESSAGE_CAPTURE"
printf '%s\n' "\$@" >> "$CALLS"
EOFMOCK
    chmod +x "$MOCK_DIR/osascript"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$MOCK_DIR" XDG_SESSION_ID="$(mktemp -u codex-macos-notify.XXXXXX)" /bin/bash -c '
        . "$HOME/.agents/hooks/lib/notify.sh"
        title=$'"'"'Title "one"\nline two'"'"'
        message=$'"'"'Message "two"\nline three'"'"'
        send_notification "$title" "$message"
    '
    [ "$status" -eq 0 ]
    EXPECTED_TITLE="$MOCK_DIR/expected-title"
    EXPECTED_MESSAGE="$MOCK_DIR/expected-message"
    printf '%s' $'Title "one"\nline two' > "$EXPECTED_TITLE"
    printf '%s' $'Message "two"\nline three' > "$EXPECTED_MESSAGE"
    cmp -s "$EXPECTED_TITLE" "$TITLE_CAPTURE"
    cmp -s "$EXPECTED_MESSAGE" "$MESSAGE_CAPTURE"
    grep -Fq 'set agentTitle to system attribute "AGENT_SIGNAL_TITLE"' "$CALLS"
    grep -Fq 'set agentMessage to system attribute "AGENT_SIGNAL_MESSAGE"' "$CALLS"
    grep -Fq 'display notification agentMessage with title agentTitle' "$CALLS"
    rm -rf "$MOCK_DIR"
    teardown_signal_hooks_home
}

# ---------------------------------------------------------------------------
# shared signal runtime and wrappers
# ---------------------------------------------------------------------------

@test "agent-signal.sh: exists and is executable" {
    setup_signal_hooks_home
    [ -x "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-signal.sh" ]
    teardown_signal_hooks_home
}

@test "agent-signal.sh: emits the WSL attention synth pattern" {
    setup_signal_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    touch "$CALLS"
    cat > "$MOCK_DIR/play" <<EOFMOCK
#!/bin/bash
printf 'play %s\n' "\$*" >> "$CALLS"
EOFMOCK
    chmod +x "$MOCK_DIR/play"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$MOCK_DIR:$PATH" WSL_DISTRO_NAME=Ubuntu bash -c "
        . '$SIGNAL_HOOKS_HOME/.agents/hooks/lib/notify.sh'
        emit_agent_signal attention Agent
    "
    [ "$status" -eq 0 ]
    expected='play -n synth 0.22 sine 784 vol 0.12 fade q 0.01 0.22 0.06'
    [ "$(cat "$CALLS")" = "$expected" ]
    rm -rf "$MOCK_DIR"
    teardown_signal_hooks_home
}

@test "agent-signal.sh: executes the wrapper entrypoint directly" {
    setup_signal_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    touch "$CALLS"
    cat > "$MOCK_DIR/play" <<EOFMOCK
#!/bin/bash
printf 'play %s\n' "\$*" >> "$CALLS"
EOFMOCK
    chmod +x "$MOCK_DIR/play"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$MOCK_DIR:$PATH" WSL_DISTRO_NAME=Ubuntu XDG_SESSION_ID="$(mktemp -u codex-agent-signal.XXXXXX)" "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-signal.sh" attention Agent
    [ "$status" -eq 0 ]
    [ "$(cat "$CALLS")" = 'play -n synth 0.22 sine 784 vol 0.12 fade q 0.01 0.22 0.06' ]
    rm -rf "$MOCK_DIR"
    teardown_signal_hooks_home
}

@test "agent-signal.sh: falls back to play when notify-send fails on linux" {
    setup_signal_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    touch "$CALLS"
    ln -s "$(command -v dirname)" "$MOCK_DIR/dirname"
    cat > "$MOCK_DIR/uname" <<'EOFMOCK'
#!/bin/bash
printf 'Linux\n'
EOFMOCK
    chmod +x "$MOCK_DIR/uname"
    cat > "$MOCK_DIR/notify-send" <<'EOFMOCK'
#!/bin/bash
printf 'raw notify-send boom: %s\n' "$*" >&2
exit 1
EOFMOCK
    chmod +x "$MOCK_DIR/notify-send"
    cat > "$MOCK_DIR/play" <<EOFMOCK
#!/bin/bash
printf 'play %s\n' "\$*" >> "$CALLS"
EOFMOCK
    chmod +x "$MOCK_DIR/play"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$MOCK_DIR" XDG_SESSION_ID="$(mktemp -u codex-linux-fallback.XXXXXX)" /bin/bash -c '
        . "$HOME/.agents/hooks/lib/notify.sh"
        emit_agent_signal attention Agent
    '
    [ "$status" -eq 0 ]
    [ "$(cat "$CALLS")" = 'play -n synth 0.16 sine 880 vol 0.10 fade q 0.01 0.16 0.05' ]
    printf '%s' "$output" | grep -q '\[agent-signal\]'
    printf '%s' "$output" | grep -q 'platform=linux event=attention policy=toast+sound'
    ! printf '%s' "$output" | grep -q 'raw notify-send boom'
    rm -rf "$MOCK_DIR"
    teardown_signal_hooks_home
}

@test "agent-signal.sh: macos signal path handles multiline agent and message" {
    setup_signal_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    TITLE_CAPTURE="$MOCK_DIR/title.capture"
    MESSAGE_CAPTURE="$MOCK_DIR/message.capture"
    touch "$CALLS"
    ln -s "$(command -v dirname)" "$MOCK_DIR/dirname"
    cat > "$MOCK_DIR/uname" <<'EOFMOCK'
#!/bin/bash
printf 'Darwin\n'
EOFMOCK
    chmod +x "$MOCK_DIR/uname"
    cat > "$MOCK_DIR/osascript" <<EOFMOCK
#!/bin/bash
printf '%s' "\$AGENT_SIGNAL_TITLE" > "$TITLE_CAPTURE"
printf '%s' "\$AGENT_SIGNAL_MESSAGE" > "$MESSAGE_CAPTURE"
printf '%s\n' "\$@" >> "$CALLS"
EOFMOCK
    chmod +x "$MOCK_DIR/osascript"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$MOCK_DIR" XDG_SESSION_ID="$(mktemp -u codex-macos-signal.XXXXXX)" /bin/bash -c '
        . "$HOME/.agents/hooks/lib/notify.sh"
        emit_agent_signal attention $'"'"'Agent "QA"\rpath'"'"' $'"'"'Message "quoted"\rbackslash'"'"'
    '
    [ "$status" -eq 0 ]
    EXPECTED_TITLE="$MOCK_DIR/expected-title"
    EXPECTED_MESSAGE="$MOCK_DIR/expected-message"
    printf '%s' $'Agent "QA"\rpath' > "$EXPECTED_TITLE"
    printf '%s' $'Message "quoted"\rbackslash' > "$EXPECTED_MESSAGE"
    cmp -s "$EXPECTED_TITLE" "$TITLE_CAPTURE"
    cmp -s "$EXPECTED_MESSAGE" "$MESSAGE_CAPTURE"
    grep -Fq 'set agentTitle to system attribute "AGENT_SIGNAL_TITLE"' "$CALLS"
    grep -Fq 'set agentMessage to system attribute "AGENT_SIGNAL_MESSAGE"' "$CALLS"
    grep -Fq 'display notification agentMessage with title agentTitle sound name "Glass"' "$CALLS"
    rm -rf "$MOCK_DIR"
    teardown_signal_hooks_home
}

@test "agent-signal.sh: falls back to beep when afplay fails on macos" {
    setup_signal_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    touch "$CALLS"
    ln -s "$(command -v dirname)" "$MOCK_DIR/dirname"
    cat > "$MOCK_DIR/uname" <<'EOFMOCK'
#!/bin/bash
printf 'Darwin\n'
EOFMOCK
    chmod +x "$MOCK_DIR/uname"
    cat > "$MOCK_DIR/afplay" <<'EOFMOCK'
#!/bin/bash
printf 'afplay failed: %s\n' "$*" >&2
exit 1
EOFMOCK
    chmod +x "$MOCK_DIR/afplay"
    cat > "$MOCK_DIR/osascript" <<EOFMOCK
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOFMOCK
    chmod +x "$MOCK_DIR/osascript"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$MOCK_DIR" XDG_SESSION_ID="$(mktemp -u codex-macos-afplay.XXXXXX)" /bin/bash -c '
        . "$HOME/.agents/hooks/lib/notify.sh"
        run_sound_only danger
    '
    [ "$status" -eq 0 ]
    grep -Fq -- '-e' "$CALLS"
    grep -Fq 'beep' "$CALLS"
    ! printf '%s' "$output" | grep -q 'afplay failed'
    rm -rf "$MOCK_DIR"
    teardown_signal_hooks_home
}

@test "agent-signal.sh: emits the WSL finished synth sequence" {
    setup_signal_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    touch "$CALLS"
    cat > "$MOCK_DIR/play" <<EOFMOCK
#!/bin/bash
printf 'play %s\n' "\$*" >> "$CALLS"
EOFMOCK
    chmod +x "$MOCK_DIR/play"
    cat > "$MOCK_DIR/sleep" <<EOFMOCK
#!/bin/bash
printf 'sleep %s\n' "\$*" >> "$CALLS"
EOFMOCK
    chmod +x "$MOCK_DIR/sleep"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$MOCK_DIR:$PATH" WSL_DISTRO_NAME=Ubuntu bash -c "
        . '$SIGNAL_HOOKS_HOME/.agents/hooks/lib/notify.sh'
        emit_agent_signal finished Agent
    "
    [ "$status" -eq 0 ]
    expected=$(cat <<'EOFEXPECTED'
play -n synth 0.18 sine 740 vol 0.12 fade q 0.01 0.18 0.05
sleep 0.3
play -n synth 0.18 sine 988 vol 0.10 fade q 0.01 0.18 0.05
EOFEXPECTED
)
    [ "$(cat "$CALLS")" = "$expected" ]
    rm -rf "$MOCK_DIR"
    teardown_signal_hooks_home
}

@test "agent-signal.sh: emits the WSL danger synth pattern" {
    setup_signal_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    touch "$CALLS"
    cat > "$MOCK_DIR/play" <<EOFMOCK
#!/bin/bash
printf 'play %s\n' "\$*" >> "$CALLS"
EOFMOCK
    chmod +x "$MOCK_DIR/play"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$MOCK_DIR:$PATH" WSL_DISTRO_NAME=Ubuntu bash -c "
        . '$SIGNAL_HOOKS_HOME/.agents/hooks/lib/notify.sh'
        emit_agent_signal danger Agent
    "
    [ "$status" -eq 0 ]
    expected='play -n synth 0.28 triangle 660-990 vol 0.11 fade q 0.01 0.28 0.08'
    [ "$(cat "$CALLS")" = "$expected" ]
    rm -rf "$MOCK_DIR"
    teardown_signal_hooks_home
}

@test "agent-signal.sh: warns once per session with required fields" {
    setup_signal_hooks_home
    UTIL_DIR="$(mktemp -d)"
    SESSION_ID="$(mktemp -u codex-test-signal.XXXXXX)"
    ln -s "$(command -v dirname)" "$UTIL_DIR/dirname"
    ln -s "$(command -v uname)" "$UTIL_DIR/uname"
    ln -s "$(command -v ps)" "$UTIL_DIR/ps"
    ln -s "$(command -v tr)" "$UTIL_DIR/tr"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$UTIL_DIR" WSL_DISTRO_NAME=Ubuntu XDG_SESSION_ID="$SESSION_ID" /bin/bash -c '
        . "$HOME/.agents/hooks/lib/notify.sh"
        {
            emit_agent_signal finished Agent
            emit_agent_signal finished Agent
        } 2>&1
    '
    [ "$status" -eq 0 ]
    [ "$(printf '%s' "$output" | grep -c '\[agent-signal\]')" -eq 1 ]
    printf '%s' "$output" | grep -q "platform=wsl event=finished policy=sound"
    printf '%s' "$output" | grep -q "requested channels: sound"
    printf '%s' "$output" | grep -q "available implementations: toast=none sound=none"
    printf '%s' "$output" | grep -q "toast checked: notify-send osascript"
    printf '%s' "$output" | grep -q "sound checked: play afplay osascript"
    rm -rf "$UTIL_DIR"
    teardown_signal_hooks_home
}

@test "agent-attention.sh: exists and is executable" {
    setup_signal_hooks_home
    [ -x "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-attention.sh" ]
    teardown_signal_hooks_home
}

@test "agent-attention.sh: delegates the attention signal" {
    setup_signal_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    touch "$CALLS"
    cat > "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-signal.sh" <<EOFMOCK
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOFMOCK
    chmod +x "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-signal.sh"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$MOCK_DIR:$PATH" "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-attention.sh"
    [ "$status" -eq 0 ]
    expected=$(cat <<'EOFEXPECTED'
attention
Agent
Needs your attention
EOFEXPECTED
)
    [ "$(cat "$CALLS")" = "$expected" ]
    rm -rf "$MOCK_DIR"
    teardown_signal_hooks_home
}

@test "agent-finished.sh: exists and is executable" {
    setup_signal_hooks_home
    [ -x "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-finished.sh" ]
    teardown_signal_hooks_home
}

@test "agent-finished.sh: delegates the finished signal" {
    setup_signal_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    touch "$CALLS"
    cat > "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-signal.sh" <<EOFMOCK
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOFMOCK
    chmod +x "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-signal.sh"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$MOCK_DIR:$PATH" "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-finished.sh"
    [ "$status" -eq 0 ]
    expected=$(cat <<'EOFEXPECTED'
finished
Agent
Finished
EOFEXPECTED
)
    [ "$(cat "$CALLS")" = "$expected" ]
    rm -rf "$MOCK_DIR"
    teardown_signal_hooks_home
}

@test "agent-danger.sh: exists and is executable" {
    setup_signal_hooks_home
    [ -x "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-danger.sh" ]
    teardown_signal_hooks_home
}

@test "agent-danger.sh: delegates the danger signal" {
    setup_signal_hooks_home
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    touch "$CALLS"
    cat > "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-signal.sh" <<EOFMOCK
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOFMOCK
    chmod +x "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-signal.sh"

    run env HOME="$SIGNAL_HOOKS_HOME" PATH="$MOCK_DIR:$PATH" "$SIGNAL_HOOKS_HOME/.agents/hooks/bin/agent-danger.sh"
    [ "$status" -eq 0 ]
    expected=$(cat <<'EOFEXPECTED'
danger
Agent
Dangerous command blocked
EOFEXPECTED
)
    [ "$(cat "$CALLS")" = "$expected" ]
    rm -rf "$MOCK_DIR"
    teardown_signal_hooks_home
}

# ---------------------------------------------------------------------------
# shared hook core
# ---------------------------------------------------------------------------

@test "env_policy.sh: blocks .env.local" {
    run bash -c ". '$ENV_POLICY_SH'; is_sensitive_env_file '.env.local'"
    [ "$status" -eq 0 ]
}

@test "env_policy.sh: allows .env.example" {
    run bash -c ". '$ENV_POLICY_SH'; is_sensitive_env_file '.env.example'"
    [ "$status" -eq 1 ]
}

@test "bash_policy.sh: fails closed when env_policy is missing" {
    setup_bash_policy_home
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'sudo cat /project/.env'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks path-qualified rm" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command '/bin/rm -rf -- /'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks path-qualified cat of sensitive env file" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'sudo /bin/cat /project/.env'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks bash -lc rm -rf /" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'bash -lc \"rm -rf /\"'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks bash -lc cat /project/.env" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'bash -lc \"cat /project/.env\"'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks zsh -c rm -rf /" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'zsh -c \"rm -rf /\"'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks dash -c cat /project/.env" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'dash -c \"cat /project/.env\"'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks env -S rm -rf /" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'env -S \"rm -rf /\"'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks sh -c psql DROP DATABASE" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'sh -c \"psql -c DROP DATABASE db;\"'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks sudo -u root rm -rf /" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'sudo -u root rm -rf /'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks sudo -u root cat /project/.env" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'sudo -u root cat /project/.env'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks env FOO=1 rm -rf /" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'env FOO=1 rm -rf /'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks env -i rm -rf /" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'env -i rm -rf /'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks /usr/bin/env FOO=1 rm -rf /" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command '/usr/bin/env FOO=1 rm -rf /'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks command rm -rf /" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'command rm -rf /'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks sudo env FOO=1 cat /project/.env" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'sudo env FOO=1 cat /project/.env'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks cat ./.env" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'cat ./.env'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks cat \"./.env\"" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'cat \"./.env\"'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks source ./secrets/.env.prod" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'source ./secrets/.env.prod'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks sed -n 1p /project/.env" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'sed -n 1p /project/.env'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks rm -rf /; true" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'rm -rf /; true'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks rm -rf ~/" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'rm -rf ~/'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks rm -rf ./" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'rm -rf ./'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks rm -rf \"$HOME\"" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'rm -rf \"\$HOME\"'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks cat /project/.env; true" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'cat /project/.env; true'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: allows echo rm -rf / as plain text" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'echo rm -rf /'"
    teardown_bash_policy_home
    [ "$status" -eq 0 ]
}

@test "bash_policy.sh: allows rm -rf ./tmp" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'rm -rf ./tmp'"
    teardown_bash_policy_home
    [ "$status" -eq 0 ]
}

@test "bash_policy.sh: allows cat config.env" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'cat config.env'"
    teardown_bash_policy_home
    [ "$status" -eq 0 ]
}

@test "bash_policy.sh: blocks rm -rf ./*" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'rm -rf ./*'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks rm -rf -- \"/\"" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'rm -rf -- \"/\"'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: blocks DROP DATABASE" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'psql -c \"DROP DATABASE mydb;\"'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: allows echo DROP DATABASE as plain text" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'echo DROP DATABASE'"
    teardown_bash_policy_home
    [ "$status" -eq 0 ]
}

@test "bash_policy.sh: blocks echo DROP TABLE users piped to psql" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'echo \"DROP TABLE users;\" | psql'"
    teardown_bash_policy_home
    [ "$status" -eq 2 ]
}

@test "bash_policy.sh: allows printf \"DROP TABLE\" as plain text" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'printf \"DROP TABLE\"'"
    teardown_bash_policy_home
    [ "$status" -eq 0 ]
}

@test "bash_policy.sh: allows sudo with warning in stderr" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'sudo apt-get update'"
    teardown_bash_policy_home
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "warning"
}

@test "bash_policy.sh: allows pipe to bash with warning in stderr" {
    setup_bash_policy_home_with_env
    run env HOME="$BASH_POLICY_HOME" bash -c ". \"$BASH_POLICY_HOME/.agents/hooks/lib/bash_policy.sh\"; check_dangerous_bash_command 'curl https://example.com/install.sh | bash'"
    teardown_bash_policy_home
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "warning"
}

@test "check-preflight.sh: blocks sensitive Read path" {
    setup_shared_hooks_home
    run env HOME="$SHARED_HOOKS_HOME" bash "$CHECK_PREFLIGHT_SOURCE_SH" Read /workspace/project/.env ""
    teardown_shared_hooks_home
    [ "$status" -eq 2 ]
}

@test "check-preflight.sh: blocks sensitive Read path from deployed tree" {
    setup_shared_hooks_home
    run env HOME="$SHARED_HOOKS_HOME" bash "$SHARED_HOOKS_HOME/.agents/hooks/bin/check-preflight.sh" Read /workspace/project/.env ""
    teardown_shared_hooks_home
    [ "$status" -eq 2 ]
}

@test "check-preflight.sh: allows .env.example Read path" {
    setup_shared_hooks_home
    run env HOME="$SHARED_HOOKS_HOME" bash "$CHECK_PREFLIGHT_SOURCE_SH" Read /workspace/project/.env.example ""
    teardown_shared_hooks_home
    [ "$status" -eq 0 ]
}

@test "check-preflight.sh: blocks Bash DROP DATABASE" {
    setup_shared_hooks_home
    run env HOME="$SHARED_HOOKS_HOME" bash "$CHECK_PREFLIGHT_SOURCE_SH" Bash "" 'psql -c "DROP DATABASE mydb;"'
    teardown_shared_hooks_home
    [ "$status" -eq 2 ]
}

@test "check-preflight.sh: blocks Bash sudo cat of sensitive env file" {
    setup_shared_hooks_home
    run env HOME="$SHARED_HOOKS_HOME" bash "$CHECK_PREFLIGHT_SOURCE_SH" Bash "" 'sudo cat /project/.env'
    teardown_shared_hooks_home
    [ "$status" -eq 2 ]
}

@test "check-preflight.sh: blocks Bash rm -rf -- /" {
    setup_shared_hooks_home
    run env HOME="$SHARED_HOOKS_HOME" bash "$CHECK_PREFLIGHT_SOURCE_SH" Bash "" 'rm -rf -- /'
    teardown_shared_hooks_home
    [ "$status" -eq 2 ]
}

PRE_TOOL_USE_SH="$CLAUDE_PRE_TOOL_USE_SH"

# Helper: run hook with JSON input
run_hook() {
    local temp_home

    temp_home="$(mktemp -d)"
    install_shared_hooks_home "$temp_home"
    printf '%s' "$1" | HOME="$temp_home" "$PRE_TOOL_USE_SH"
    local status=$?
    rm -rf "$temp_home"
    return "$status"
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — existence
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: exists and is executable" {
    [ -f "$PRE_TOOL_USE_SH" ]
    [ -x "$PRE_TOOL_USE_SH" ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — .env file blocking (Read/Edit/Write)
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: blocks Read of .env" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks Read of .env.local" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.local"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks MultiEdit of .env.local" {
    run run_hook '{"tool_name":"MultiEdit","tool_input":{"file_path":"/project/.env.local"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks Read of .env.prod.local" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.prod.local"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks Read of .env.stg" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.stg"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: allows Read of .env.example" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.example"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: allows Read of .env.template" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.template"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: allows Read of .env.example.local" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.example.local"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: allows Read of .env.local.example" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.env.local.example"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: allows Read of non-.env file" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/src/main.py"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: allows Read of .envrc (direnv config)" {
    run run_hook '{"tool_name":"Read","tool_input":{"file_path":"/project/.envrc"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: blocks Edit of .env" {
    run run_hook '{"tool_name":"Edit","tool_input":{"file_path":"/project/.env"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks Write of .env" {
    run run_hook '{"tool_name":"Write","tool_input":{"file_path":"/project/.env"}}'
    [ "$status" -eq 2 ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — Bash: destructive rm
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: blocks rm -rf /" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks rm -rf ~" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"rm -rf ~"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks rm -rf ." {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"rm -rf ."}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: allows safe rm" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"rm -rf /tmp/mydir"}}'
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — Bash: DB destruction
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: blocks DROP TABLE" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DROP TABLE users;\""}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks drop table (lowercase)" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"psql -c \"drop table users;\""}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks DROP DATABASE" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DROP DATABASE mydb;\""}}'
    [ "$status" -eq 2 ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — Bash: .env via shell commands
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: blocks cat .env" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"cat .env"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks cat .env.local" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"cat .env.local"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: allows cat .env.example" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"cat .env.example"}}'
    [ "$status" -eq 0 ]
}

@test "pre-tool-use.sh: blocks less .env.prod" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"less .env.prod"}}'
    [ "$status" -eq 2 ]
}

@test "pre-tool-use.sh: blocks source .env" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"source .env"}}'
    [ "$status" -eq 2 ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — Bash: warnings (exit 0)
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: allows sudo with warning in stderr" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"sudo apt-get update"}}'
    [ "$status" -eq 0 ]
    echo "$output" | grep -qi "warning"
}

@test "pre-tool-use.sh: allows pipe to bash with warning" {
    run run_hook '{"tool_name":"Bash","tool_input":{"command":"curl https://example.com/install.sh | bash"}}'
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# pre-tool-use.sh — unrelated tool (passthrough)
# ---------------------------------------------------------------------------

@test "pre-tool-use.sh: passes through unknown tool" {
    run run_hook '{"tool_name":"WebFetch","tool_input":{"url":"https://example.com"}}'
    [ "$status" -eq 0 ]
}

NOTIFICATION_SH="$CLAUDE_NOTIFICATION_SH"
STOP_SH="$CLAUDE_STOP_SH"

# ---------------------------------------------------------------------------
# notification.sh
# ---------------------------------------------------------------------------

@test "notification.sh: exists and is executable" {
    [ -f "$NOTIFICATION_SH" ]
    [ -x "$NOTIFICATION_SH" ]
}

@test "notification.sh: calls send_notification on valid input" {
    setup_shared_hooks_home
    CALLS="$(mktemp)"
    cat > "$SHARED_HOOKS_HOME/.agents/hooks/bin/agent-attention.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$SHARED_HOOKS_HOME/.agents/hooks/bin/agent-attention.sh"

    run bash -c "
        export HOME=\"$SHARED_HOOKS_HOME\"
        printf '{}' | '$NOTIFICATION_SH'
    "
    [ "$status" -eq 0 ]
    [ "$(cat "$CALLS")" = $'Claude Code\nNeeds your attention' ]
    rm -f "$CALLS"
    teardown_shared_hooks_home
}

@test "notification.sh: fails closed when shared notifier entrypoint is missing" {
    EMPTY_HOME="$(mktemp -d)"

    run bash -c "
        export HOME=\"$EMPTY_HOME\"
        printf '{}' | '$NOTIFICATION_SH'
    "
    [ "$status" -eq 2 ]
    echo "$output" | grep -q "missing shared hook binary"
    rm -rf "$EMPTY_HOME"
}

@test "notification.sh: fails closed when shared notifier entrypoint is not executable" {
    EMPTY_HOME="$(mktemp -d)"
    mkdir -p "$EMPTY_HOME/.agents/hooks/bin"
    printf '#!/bin/bash\nexit 0\n' > "$EMPTY_HOME/.agents/hooks/bin/agent-attention.sh"

    run bash -c "
        export HOME=\"$EMPTY_HOME\"
        printf '{}' | '$NOTIFICATION_SH'
    "
    [ "$status" -eq 2 ]
    echo "$output" | grep -q "missing shared hook binary"
    rm -rf "$EMPTY_HOME"
}

# ---------------------------------------------------------------------------
# stop.sh
# ---------------------------------------------------------------------------

@test "stop.sh: exists and is executable" {
    [ -f "$STOP_SH" ]
    [ -x "$STOP_SH" ]
}

@test "stop.sh: exits 0 immediately when stop_hook_active is true" {
    setup_shared_hooks_home
    run bash -c "export HOME=\"$SHARED_HOOKS_HOME\"; printf '{\"stop_hook_active\":true,\"session_id\":\"test-guard\"}' | '$STOP_SH'"
    [ "$status" -eq 0 ]
    teardown_shared_hooks_home
}

@test "stop.sh: does not notify on first call (creates marker only)" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    printf '#!/bin/bash\necho "$@" >> "%s"\n' "$CALLS" > "$MOCK_DIR/notify-send"
    chmod +x "$MOCK_DIR/notify-send"
    setup_shared_hooks_home

    SESSION="test-session-first-$$"
    run bash -c "
        export HOME=\"$SHARED_HOOKS_HOME\"
        export TMPDIR=\"$MOCK_DIR\"
        export PATH=\"$MOCK_DIR:\$PATH\"
        export WSL_DISTRO_NAME=Ubuntu
        printf '{\"stop_hook_active\":false,\"session_id\":\"$SESSION\"}' | '$STOP_SH'
    "
    [ "$status" -eq 0 ]
    # notify-send should NOT have been called (first call just writes marker)
    [ ! -f "$CALLS" ] || [ ! -s "$CALLS" ]
    rm -rf "$MOCK_DIR"
    teardown_shared_hooks_home
}

@test "stop.sh: notifies when elapsed time >= 10 seconds" {
    setup_shared_hooks_home
    CALLS="$(mktemp)"
    MARKER_DIR="$(mktemp -d)"
    cat > "$SHARED_HOOKS_HOME/.agents/hooks/bin/agent-finished.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$SHARED_HOOKS_HOME/.agents/hooks/bin/agent-finished.sh"

    SESSION="test-session-elapsed-$$"
    # Write a marker with a timestamp 15 seconds in the past
    PAST=$(( $(date +%s) - 15 ))
    printf '%s\n' "$PAST" > "$MARKER_DIR/claude-last-stop-$SESSION"

    run bash -c "
        export HOME=\"$SHARED_HOOKS_HOME\"
        export TMPDIR=\"$MARKER_DIR\"
        printf '{\"stop_hook_active\":false,\"session_id\":\"$SESSION\"}' | '$STOP_SH'
    "
    [ "$status" -eq 0 ]
    [ "$(cat "$CALLS")" = $'Claude Code\nFinished' ]
    rm -f "$CALLS"
    rm -rf "$MARKER_DIR"
    teardown_shared_hooks_home
}

@test "stop.sh: does not notify when elapsed time < 10 seconds" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    printf '#!/bin/bash\necho "$@" >> "%s"\n' "$CALLS" > "$MOCK_DIR/notify-send"
    chmod +x "$MOCK_DIR/notify-send"
    setup_shared_hooks_home

    SESSION="test-session-fast-$$"
    # Write a marker just 2 seconds ago
    RECENT=$(( $(date +%s) - 2 ))
    printf '%s\n' "$RECENT" > "$MOCK_DIR/claude-last-stop-$SESSION"

    run bash -c "
        export HOME=\"$SHARED_HOOKS_HOME\"
        export TMPDIR=\"$MOCK_DIR\"
        export PATH=\"$MOCK_DIR:\$PATH\"
        export WSL_DISTRO_NAME=Ubuntu
        printf '{\"stop_hook_active\":false,\"session_id\":\"$SESSION\"}' | '$STOP_SH'
    "
    [ "$status" -eq 0 ]
    [ ! -f "$CALLS" ] || [ ! -s "$CALLS" ]
    rm -rf "$MOCK_DIR"
    teardown_shared_hooks_home
}
