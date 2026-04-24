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

extract_table_block() {
    local table_name="$1"
    local next_table_name="$2"
    local file="$3"

    awk -v table="^[[]""$table_name""[]]$" -v next_table="^[[]""$next_table_name""[]]$" '
        $0 ~ table { in_table = 1 }
        in_table {
            if ($0 ~ next_table) {
                exit
            }
            print
        }
    ' "$file"
}

@test "new install: enables codex_hooks feature" {
    sh "$SCRIPT"

    run grep -q '^codex_hooks = true$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]
}

@test "new install: writes curated comments and richer tui status line" {
    sh "$SCRIPT"

    run grep -q '^# Curated from the official Codex sample config:$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^# https://developers.openai.com/codex/config-sample$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^# service_tier = "flex"' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^model_reasoning_effort = "medium"$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^# model_context_window = 128000       # tokens; default: auto for model$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^# model_auto_compact_token_limit = 64000  # tokens; unset uses model defaults$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^# tool_output_token_limit = 12000     # tokens stored per tool output$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^# background_terminal_max_timeout = 300000$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^# log_dir = "/absolute/path/to/codex-logs" # directory for Codex logs; default: "\$CODEX_HOME/log"$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^# sqlite_home = "/absolute/path/to/codex-state" # optional SQLite-backed runtime state directory$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^# notify = \["notify-send", "Codex"\]$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^# model = ' "$HOME/.codex/config.toml"
    [ "$status" -eq 1 ]

    run extract_table_block "tui" "features" "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]
    [ "$output" = "$(cat <<'EOF'
[tui]
status_line = [
    "model-with-reasoning",
    "git-branch",
    "context-used",
    "context-window-size",
    "used-tokens",
    "five-hour-limit",
    "weekly-limit",
]

# Desktop notifications from the TUI: boolean or filtered list. Default: true
# Examples: false | ["agent-turn-complete", "approval-requested"]
notifications = true

# When notifications fire: unfocused (default) | always
notification_condition = "always"
EOF
)" ]
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

@test "existing config: preserves user model key" {
    cat > "$HOME/.codex/config.toml" <<'EOF'
model = "gpt-legacy"

[projects.example]
trust_level = "trusted"
EOF

    sh "$SCRIPT"

    run grep -q '^model = "gpt-legacy"$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^\[projects\.example\]$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]
}

@test "existing config: preserves model while overwriting managed values" {
    cat > "$HOME/.codex/config.toml" <<'EOF'
model = "gpt-legacy"
model_reasoning_effort = "high"
model_context_window = 99999
model_auto_compact_token_limit = 55555
tool_output_token_limit = 7777
approval_policy = "never"
sandbox_mode = "danger-full-access"
personality = "friendly"
background_terminal_max_timeout = 12345
log_dir = "/tmp/codex-log"
sqlite_home = "/tmp/codex-sqlite"
notify = ["~/.codex/hooks/notify.sh"]

[tui]
status_line = [
    "current-dir",
]
notifications = false
notification_condition = "unfocused"

[features]
memories = false
codex_hooks = false

[profiles.conservative]
approval_policy = "never"
sandbox_mode = "danger-full-access"

[projects.example]
trust_level = "trusted"
EOF

    sh "$SCRIPT"

    run grep -q '^model = "gpt-legacy"$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^model_reasoning_effort = "medium"$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^personality = "pragmatic"$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^approval_policy = "on-request"$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^sandbox_mode = "workspace-write"$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^background_terminal_max_timeout =' "$HOME/.codex/config.toml"
    [ "$status" -eq 1 ]

    run grep -q '^model_context_window =' "$HOME/.codex/config.toml"
    [ "$status" -eq 1 ]

    run grep -q '^model_auto_compact_token_limit =' "$HOME/.codex/config.toml"
    [ "$status" -eq 1 ]

    run grep -q '^tool_output_token_limit =' "$HOME/.codex/config.toml"
    [ "$status" -eq 1 ]

    run grep -q '^log_dir =' "$HOME/.codex/config.toml"
    [ "$status" -eq 1 ]

    run grep -q '^sqlite_home =' "$HOME/.codex/config.toml"
    [ "$status" -eq 1 ]

    run grep -q '^notify =' "$HOME/.codex/config.toml"
    [ "$status" -eq 1 ]

    run extract_table_block "tui" "features" "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]
    [ "$output" = "$(cat <<'EOF'
[tui]
status_line = [
    "model-with-reasoning",
    "git-branch",
    "context-used",
    "context-window-size",
    "used-tokens",
    "five-hour-limit",
    "weekly-limit",
]

# Desktop notifications from the TUI: boolean or filtered list. Default: true
# Examples: false | ["agent-turn-complete", "approval-requested"]
notifications = true

# When notifications fire: unfocused (default) | always
notification_condition = "always"
EOF
)" ]

    run grep -q '^codex_hooks = true$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^memories = true$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^\[profiles\.conservative\]$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^\[projects\.example\]$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]

    run grep -q '^trust_level = "trusted"$' "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]
}

@test "existing config: overwrites whole tui section even with trailing array comment" {
    cat > "$HOME/.codex/config.toml" <<'EOF'
[tui]
status_line = [
    "current-dir",
] # user comment
notifications = false
notification_condition = "unfocused"
EOF

    sh "$SCRIPT"

    run extract_table_block "tui" "features" "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]
    [ "$output" = "$(cat <<'EOF'
[tui]
status_line = [
    "model-with-reasoning",
    "git-branch",
    "context-used",
    "context-window-size",
    "used-tokens",
    "five-hour-limit",
    "weekly-limit",
]

# Desktop notifications from the TUI: boolean or filtered list. Default: true
# Examples: false | ["agent-turn-complete", "approval-requested"]
notifications = true

# When notifications fire: unfocused (default) | always
notification_condition = "always"
EOF
)" ]
}

@test "existing config: overwrites whole tui section after single-line status_line comment" {
    cat > "$HOME/.codex/config.toml" <<'EOF'
[tui]
status_line = ["current-dir"] # user comment
notifications = false
notification_condition = "unfocused"
EOF

    sh "$SCRIPT"

    run extract_table_block "tui" "features" "$HOME/.codex/config.toml"
    [ "$status" -eq 0 ]
    [ "$output" = "$(cat <<'EOF'
[tui]
status_line = [
    "model-with-reasoning",
    "git-branch",
    "context-used",
    "context-window-size",
    "used-tokens",
    "five-hour-limit",
    "weekly-limit",
]

# Desktop notifications from the TUI: boolean or filtered list. Default: true
# Examples: false | ["agent-turn-complete", "approval-requested"]
notifications = true

# When notifications fire: unfocused (default) | always
notification_condition = "always"
EOF
)" ]
}

@test "existing config: merge is idempotent across repeated runs" {
    cat > "$HOME/.codex/config.toml" <<'EOF'
model = "gpt-legacy"
approval_policy = "never"
sandbox_mode = "danger-full-access"
notify = ["~/.codex/hooks/notify.sh"]

[tui]
status_line = [
    "current-dir",
] # keep this comment
notifications = false
notification_condition = "unfocused"

[projects.example]
trust_level = "trusted"
EOF

    sh "$SCRIPT"
    first_contents="$(cat "$HOME/.codex/config.toml")"

    sh "$SCRIPT"
    second_contents="$(cat "$HOME/.codex/config.toml")"

    [ "$first_contents" = "$second_contents" ]
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
