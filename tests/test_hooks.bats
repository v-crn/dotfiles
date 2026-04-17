#!/usr/bin/env bats
# Tests for Claude Code hook scripts

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI_ROOT="$(tr -d '[:space:]' < "$REPO_ROOT/.chezmoiroot")"
HOOKS_DIR="$REPO_ROOT/$CHEZMOI_ROOT/dot_claude/hooks"
PLATFORM_SH="$HOOKS_DIR/lib/platform.sh"

# ---------------------------------------------------------------------------
# lib/platform.sh
# ---------------------------------------------------------------------------

@test "platform.sh: exists and is executable" {
    [ -f "$PLATFORM_SH" ]
    [ -x "$PLATFORM_SH" ]
}

@test "platform.sh: detects macOS when uname returns Darwin" {
    run bash -c "uname() { echo Darwin; }; export -f uname; unset WSL_DISTRO_NAME; . '$PLATFORM_SH'; echo \$PLATFORM"
    [ "$output" = "macos" ]
}

@test "platform.sh: detects wsl when WSL_DISTRO_NAME is set" {
    run bash -c "WSL_DISTRO_NAME=Ubuntu . '$PLATFORM_SH'; echo \$PLATFORM"
    [ "$output" = "wsl" ]
}

@test "platform.sh: returns linux on plain Linux without WSL" {
    run bash -c "uname() { echo Linux; }; export -f uname; unset WSL_DISTRO_NAME; . '$PLATFORM_SH'; echo \$PLATFORM"
    [ "$output" = "linux" ]
}

@test "platform.sh: returns unknown on unrecognized uname output" {
    run bash -c "uname() { echo SunOS; }; export -f uname; unset WSL_DISTRO_NAME; . '$PLATFORM_SH'; echo \$PLATFORM"
    [ "$output" = "unknown" ]
}

NOTIFY_SH="$HOOKS_DIR/lib/notify.sh"

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
