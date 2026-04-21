#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI_ROOT="$(tr -d '[:space:]' < "$REPO_ROOT/.chezmoiroot")"
SCRIPT="$REPO_ROOT/$CHEZMOI_ROOT/dot_codex/run_apply-codex-config.sh"
BASH_BIN="$(command -v bash)"

setup() {
    TEST_HOME="$(mktemp -d)"
    mkdir -p "$TEST_HOME/.codex"
    export HOME="$TEST_HOME"
}

teardown() {
    rm -rf "$TEST_HOME"
}

@test "new install: enables codex_hooks feature" {
    sh "$SCRIPT"

    run grep -q '^codex_hooks = true$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]
}

@test "existing config: strips legacy notify key" {
    cat > "$HOME/.codex/config.toml" <<'EOF'
notify = ["~/.codex/hooks/notify.sh"]

[projects.example]
trust_level = "trusted"
EOF

    sh "$SCRIPT"

    run grep -q '^notify =' "$HOME/.codex/config.toml"
    [ "$status" -eq 1 ]

    run grep -q '^\[projects\.example\]$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]
}

@test "hooks.json template renders expected global hooks" {
    rendered="$(chezmoi execute-template --source "$REPO_ROOT" < "$REPO_ROOT/home/dot_codex/private_hooks.json.tmpl")"
    hooks_json="$(mktemp)"
    printf '%s' "$rendered" > "$hooks_json"

    run jq -e '
        .hooks.PreToolUse[0].matcher == "Bash" and
        .hooks.PreToolUse[0].hooks[0].command == "~/.codex/hooks/pre-tool-use.sh" and
        .hooks.Stop[0].hooks[0].command == "~/.codex/hooks/stop.sh"
    ' "$hooks_json"
    [ "$status" -eq 0 ]
    rm -f "$hooks_json"
}

@test "pre-tool-use adapter denies Bash commands via shared policy" {
    mkdir -p "$TEST_HOME/.agents/hooks/bin"
    cat > "$TEST_HOME/.agents/hooks/bin/check-preflight.sh" <<'EOF'
#!/bin/bash
exit 2
EOF
    chmod +x "$TEST_HOME/.agents/hooks/bin/check-preflight.sh"

    run env HOME="$TEST_HOME" "$BASH_BIN" "$REPO_ROOT/home/dot_codex/hooks/executable_pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}
EOF

    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
}

@test "pre-tool-use adapter blocks when jq is missing" {
    EMPTY_PATH="$(mktemp -d)"

    run env HOME="$TEST_HOME" PATH="$EMPTY_PATH" "$BASH_BIN" "$REPO_ROOT/home/dot_codex/hooks/executable_pre-tool-use.sh" 2>&1 <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"echo hi"}}
EOF

    [ "$status" -eq 2 ]
}

@test "stop adapter returns continue JSON for stop_hook_active" {
    run env HOME="$TEST_HOME" "$BASH_BIN" "$REPO_ROOT/home/dot_codex/hooks/executable_stop.sh" <<'EOF'
{"stop_hook_active":true}
EOF

    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.continue == true' >/dev/null
}

@test "stop adapter invokes shared notifier on stop_hook_active false" {
    mkdir -p "$TEST_HOME/.agents/hooks/bin"
    cat > "$TEST_HOME/.agents/hooks/bin/notify-finished.sh" <<'EOF'
#!/bin/bash
printf '%s\n' "$*"
EOF
    chmod +x "$TEST_HOME/.agents/hooks/bin/notify-finished.sh"

    run env HOME="$TEST_HOME" "$BASH_BIN" "$REPO_ROOT/home/dot_codex/hooks/executable_stop.sh" <<'EOF'
{"stop_hook_active":false}
EOF

    [ "$status" -eq 0 ]
    [ "$output" = "Codex Finished" ]
}

@test "stop adapter invokes shared notifier when stop_hook_active is missing" {
    mkdir -p "$TEST_HOME/.agents/hooks/bin"
    cat > "$TEST_HOME/.agents/hooks/bin/notify-finished.sh" <<'EOF'
#!/bin/bash
printf '%s\n' "$*"
EOF
    chmod +x "$TEST_HOME/.agents/hooks/bin/notify-finished.sh"

    run env HOME="$TEST_HOME" "$BASH_BIN" "$REPO_ROOT/home/dot_codex/hooks/executable_stop.sh" <<'EOF'
{}
EOF

    [ "$status" -eq 0 ]
    [ "$output" = "Codex Finished" ]
}

@test "stop adapter blocks when jq is missing" {
    EMPTY_PATH="$(mktemp -d)"

    run env HOME="$TEST_HOME" PATH="$EMPTY_PATH" "$BASH_BIN" "$REPO_ROOT/home/dot_codex/hooks/executable_stop.sh" 2>&1 <<'EOF'
{"stop_hook_active":true}
EOF

    [ "$status" -eq 2 ]
}
