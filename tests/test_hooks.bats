#!/usr/bin/env bats
# Tests for Claude Code hook scripts

HOOKS_DIR="$HOME/.claude/hooks"
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

PRE_TOOL_USE_SH="$HOOKS_DIR/pre-tool-use.sh"

# Helper: run hook with JSON input
run_hook() {
    printf '%s' "$1" | bash "$PRE_TOOL_USE_SH"
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

NOTIFICATION_SH="$HOOKS_DIR/notification.sh"
STOP_SH="$HOOKS_DIR/stop.sh"

# ---------------------------------------------------------------------------
# notification.sh
# ---------------------------------------------------------------------------

@test "notification.sh: exists and is executable" {
    [ -f "$NOTIFICATION_SH" ]
    [ -x "$NOTIFICATION_SH" ]
}

@test "notification.sh: calls send_notification on valid input" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    printf '#!/bin/bash\necho "$@" >> "%s"\n' "$CALLS" > "$MOCK_DIR/notify-send"
    chmod +x "$MOCK_DIR/notify-send"

    run bash -c "
        export PATH=\"$MOCK_DIR:\$PATH\"
        export WSL_DISTRO_NAME=Ubuntu
        printf '{}' | bash '$NOTIFICATION_SH'
    "
    [ "$status" -eq 0 ]
    [ -f "$CALLS" ]
    grep -q "Claude Code" "$CALLS"
    rm -rf "$MOCK_DIR"
}

# ---------------------------------------------------------------------------
# stop.sh
# ---------------------------------------------------------------------------

@test "stop.sh: exists and is executable" {
    [ -f "$STOP_SH" ]
    [ -x "$STOP_SH" ]
}

@test "stop.sh: exits 0 immediately when stop_hook_active is true" {
    run bash -c "printf '{\"stop_hook_active\":true,\"session_id\":\"test-guard\"}' | bash '$STOP_SH'"
    [ "$status" -eq 0 ]
}

@test "stop.sh: does not notify on first call (creates marker only)" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    printf '#!/bin/bash\necho "$@" >> "%s"\n' "$CALLS" > "$MOCK_DIR/notify-send"
    chmod +x "$MOCK_DIR/notify-send"

    SESSION="test-session-first-$$"
    run bash -c "
        export TMPDIR=\"$MOCK_DIR\"
        export PATH=\"$MOCK_DIR:\$PATH\"
        export WSL_DISTRO_NAME=Ubuntu
        printf '{\"stop_hook_active\":false,\"session_id\":\"$SESSION\"}' | bash '$STOP_SH'
    "
    [ "$status" -eq 0 ]
    # notify-send should NOT have been called (first call just writes marker)
    [ ! -f "$CALLS" ] || [ ! -s "$CALLS" ]
    rm -rf "$MOCK_DIR"
}

@test "stop.sh: notifies when elapsed time >= 10 seconds" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    printf '#!/bin/bash\necho "$@" >> "%s"\n' "$CALLS" > "$MOCK_DIR/notify-send"
    chmod +x "$MOCK_DIR/notify-send"

    SESSION="test-session-elapsed-$$"
    # Write a marker with a timestamp 15 seconds in the past
    PAST=$(( $(date +%s) - 15 ))
    printf '%s\n' "$PAST" > "$MOCK_DIR/claude-last-stop-$SESSION"

    run bash -c "
        export TMPDIR=\"$MOCK_DIR\"
        export PATH=\"$MOCK_DIR:\$PATH\"
        export WSL_DISTRO_NAME=Ubuntu
        printf '{\"stop_hook_active\":false,\"session_id\":\"$SESSION\"}' | bash '$STOP_SH'
    "
    [ "$status" -eq 0 ]
    [ -f "$CALLS" ] && [ -s "$CALLS" ]
    rm -rf "$MOCK_DIR"
}

@test "stop.sh: does not notify when elapsed time < 10 seconds" {
    MOCK_DIR="$(mktemp -d)"
    CALLS="$MOCK_DIR/calls.log"
    printf '#!/bin/bash\necho "$@" >> "%s"\n' "$CALLS" > "$MOCK_DIR/notify-send"
    chmod +x "$MOCK_DIR/notify-send"

    SESSION="test-session-fast-$$"
    # Write a marker just 2 seconds ago
    RECENT=$(( $(date +%s) - 2 ))
    printf '%s\n' "$RECENT" > "$MOCK_DIR/claude-last-stop-$SESSION"

    run bash -c "
        export TMPDIR=\"$MOCK_DIR\"
        export PATH=\"$MOCK_DIR:\$PATH\"
        export WSL_DISTRO_NAME=Ubuntu
        printf '{\"stop_hook_active\":false,\"session_id\":\"$SESSION\"}' | bash '$STOP_SH'
    "
    [ "$status" -eq 0 ]
    [ ! -f "$CALLS" ] || [ ! -s "$CALLS" ]
    rm -rf "$MOCK_DIR"
}
