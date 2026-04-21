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

install_codex_hooks_home() {
    local target_home="$1"

    mkdir -p "$target_home/.codex/hooks"
    cp "$REPO_ROOT/home/dot_codex/hooks/executable_pre-tool-use.sh" "$target_home/.codex/hooks/pre-tool-use.sh"
    cp "$REPO_ROOT/home/dot_codex/hooks/executable_stop.sh" "$target_home/.codex/hooks/stop.sh"
    chmod +x "$target_home/.codex/hooks/pre-tool-use.sh" "$target_home/.codex/hooks/stop.sh"
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
    install_shared_hooks_home "$HOME"
    install_codex_hooks_home "$HOME"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-danger.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-danger.sh"

    run env HOME="$HOME" "$HOME/.codex/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}
EOF

    [ "$status" -eq 0 ]
    printf '%s\n' "$output" | tail -n1 | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
    [ "$(cat "$CALLS")" = $'Codex\nDangerous command blocked' ]
    rm -f "$CALLS"
}

@test "pre-tool-use adapter blocks when jq is missing" {
    EMPTY_PATH="$(mktemp -d)"

    run env HOME="$TEST_HOME" PATH="$EMPTY_PATH" "$BASH_BIN" "$REPO_ROOT/home/dot_codex/hooks/executable_pre-tool-use.sh" 2>&1 <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"echo hi"}}
EOF

    [ "$status" -eq 2 ]
}

@test "pre-tool-use adapter preserves sudo warning in stderr" {
    install_shared_hooks_home "$HOME"
    install_codex_hooks_home "$HOME"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-danger.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-danger.sh"

    run env HOME="$HOME" "$HOME/.codex/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"sudo apt-get update"}}
EOF

    [ "$status" -eq 0 ]
    printf '%s' "$output" | grep -q 'Warning: sudo usage detected.'
    [ ! -s "$CALLS" ]
    rm -f "$CALLS"
}

@test "pre-tool-use adapter does not emit agent-danger on shared library failure" {
    install_shared_hooks_home "$HOME"
    install_codex_hooks_home "$HOME"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-danger.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-danger.sh"
    rm -f "$HOME/.agents/hooks/lib/env_policy.sh" "$HOME/.agents/hooks/lib/executable_env_policy.sh"

    run env HOME="$HOME" "$HOME/.codex/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}
EOF

    [ "$status" -eq 0 ]
    printf '%s\n' "$output" | tail -n1 | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
    printf '%s' "$output" | grep -q 'Blocked: missing shared hook library: env_policy'
    [ ! -s "$CALLS" ]
    rm -f "$CALLS"
}

@test "pre-tool-use adapter emits agent-danger on dangerous denial" {
    install_shared_hooks_home "$HOME"
    install_codex_hooks_home "$HOME"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-danger.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-danger.sh"

    run env HOME="$HOME" "$HOME/.codex/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}
EOF

    [ "$status" -eq 0 ]
    printf '%s\n' "$output" | tail -n1 | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null
    [ "$(cat "$CALLS")" = $'Codex\nDangerous command blocked' ]
    rm -f "$CALLS"
}

@test "stop adapter returns continue JSON for stop_hook_active" {
    install_shared_hooks_home "$HOME"
    install_codex_hooks_home "$HOME"
    run env HOME="$HOME" "$HOME/.codex/hooks/stop.sh" <<'EOF'
{"stop_hook_active":true}
EOF

    [ "$status" -eq 0 ]
    echo "$output" | jq -e '.continue == true' >/dev/null
}

@test "stop adapter invokes agent-finished on stop_hook_active false" {
    install_shared_hooks_home "$HOME"
    install_codex_hooks_home "$HOME"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-finished.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-finished.sh"

    run env HOME="$HOME" "$HOME/.codex/hooks/stop.sh" <<'EOF'
{"stop_hook_active":false}
EOF

    [ "$status" -eq 0 ]
    [ "$(cat "$CALLS")" = $'Codex\nFinished' ]
    rm -f "$CALLS"
}

@test "stop adapter invokes agent-finished when stop_hook_active is missing" {
    install_shared_hooks_home "$HOME"
    install_codex_hooks_home "$HOME"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-finished.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-finished.sh"

    run env HOME="$HOME" "$HOME/.codex/hooks/stop.sh" <<'EOF'
{}
EOF

    [ "$status" -eq 0 ]
    [ "$(cat "$CALLS")" = $'Codex\nFinished' ]
    rm -f "$CALLS"
}

@test "stop adapter blocks when jq is missing" {
    EMPTY_PATH="$(mktemp -d)"

    run env HOME="$TEST_HOME" PATH="$EMPTY_PATH" "$BASH_BIN" "$REPO_ROOT/home/dot_codex/hooks/executable_stop.sh" 2>&1 <<'EOF'
{"stop_hook_active":true}
EOF

    [ "$status" -eq 2 ]
}
