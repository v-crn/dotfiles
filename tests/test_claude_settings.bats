#!/usr/bin/env bats
# Tests for home/dot_claude/run_apply-claude-settings.sh

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI_ROOT="$(cat "$REPO_ROOT/.chezmoiroot" | tr -d '[:space:]')"
SCRIPT="$REPO_ROOT/$CHEZMOI_ROOT/dot_claude/run_apply-claude-settings.sh"

setup() {
    TEST_HOME="$(mktemp -d)"
    mkdir -p "$TEST_HOME/.claude"
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

# ---------------------------------------------------------------------------
# Script existence
# ---------------------------------------------------------------------------

@test "script exists" {
    [ -f "$SCRIPT" ]
}

@test "script is executable" {
    [ -x "$SCRIPT" ]
}

# ---------------------------------------------------------------------------
# New install (no existing settings.json)
# ---------------------------------------------------------------------------

@test "new install: creates settings.json" {
    "$SCRIPT"
    [ -f "$HOME/.claude/settings.json" ]
}

@test "new install: language is Japanese" {
    "$SCRIPT"
    run jq -r '.language' "$HOME/.claude/settings.json"
    [ "$output" = "Japanese" ]
}

@test "new install: does not include enabledPlugins" {
    "$SCRIPT"
    run jq 'has("enabledPlugins")' "$HOME/.claude/settings.json"
    [ "$output" = "false" ]
}

@test "new install: includes desired hooks" {
    "$SCRIPT"
    run jq 'has("hooks")' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
    run jq '.hooks | has("PreToolUse")' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
    run jq '.hooks | has("Notification")' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
    run jq '.hooks | has("Stop")' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
}

# ---------------------------------------------------------------------------
# Merge: overwrite keys
# ---------------------------------------------------------------------------

@test "merge: overwrites language with desired value" {
    printf '{"language":"English"}\n' > "$HOME/.claude/settings.json"
    "$SCRIPT"
    run jq -r '.language' "$HOME/.claude/settings.json"
    [ "$output" = "Japanese" ]
}

@test "merge: overwrites env with desired value" {
    printf '{"env":{"MAX_THINKING_TOKENS":"999"}}\n' > "$HOME/.claude/settings.json"
    "$SCRIPT"
    run jq -r '.env.MAX_THINKING_TOKENS' "$HOME/.claude/settings.json"
    [ "$output" = "12000" ]
}

# ---------------------------------------------------------------------------
# Merge: union arrays
# ---------------------------------------------------------------------------

@test "merge: unions permissions.allow without duplicates" {
    printf '{"permissions":{"allow":["Bash(npm *)","Read(.env.example)"]}}\n' \
        > "$HOME/.claude/settings.json"
    "$SCRIPT"
    run jq -r '.permissions.allow | contains(["Bash(npm *)"])' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
    run jq '[.permissions.allow[] | select(. == "Read(.env.example)")] | length' \
        "$HOME/.claude/settings.json"
    [ "$output" = "1" ]
}

@test "merge: unions permissions.deny without duplicates" {
    printf '{"permissions":{"deny":["Bash(rm -rf *)","Read(.env)"]}}\n' \
        > "$HOME/.claude/settings.json"
    "$SCRIPT"
    run jq -r '.permissions.deny | contains(["Bash(rm -rf *)"])' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
    run jq '[.permissions.deny[] | select(. == "Read(.env)")] | length' \
        "$HOME/.claude/settings.json"
    [ "$output" = "1" ]
}

@test "merge: unions sandbox.excludedCommands without duplicates" {
    printf '{"sandbox":{"excludedCommands":["git","npm"]}}\n' \
        > "$HOME/.claude/settings.json"
    "$SCRIPT"
    run jq -r '.sandbox.excludedCommands | contains(["npm"])' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
    run jq '[.sandbox.excludedCommands[] | select(. == "git")] | length' \
        "$HOME/.claude/settings.json"
    [ "$output" = "1" ]
}

@test "merge: unions sandbox.network.allowedHosts without duplicates" {
    printf '{"sandbox":{"network":{"allowedHosts":["api.github.com","custom.example.com"]}}}\n' \
        > "$HOME/.claude/settings.json"
    "$SCRIPT"
    run jq -r '.sandbox.network.allowedHosts | contains(["custom.example.com"])' \
        "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
    run jq '[.sandbox.network.allowedHosts[] | select(. == "api.github.com")] | length' \
        "$HOME/.claude/settings.json"
    [ "$output" = "1" ]
}

# ---------------------------------------------------------------------------
# Merge: preserve fields
# ---------------------------------------------------------------------------

@test "merge: preserves enabledPlugins from existing" {
    printf '{"enabledPlugins":{"my-plugin@org":true}}\n' \
        > "$HOME/.claude/settings.json"
    "$SCRIPT"
    run jq -r '.enabledPlugins["my-plugin@org"]' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
}

@test "merge: unions existing hooks with desired hooks per event" {
    cat > "$HOME/.claude/settings.json" <<'EOF'
{
    "hooks": {
        "PreToolUse": [{"matcher":"Skill","hooks":[{"type":"command","command":"npx ccstatusline"}]}],
        "UserPromptSubmit": [{"hooks":[{"type":"command","command":"npx ccstatusline --hook"}]}]
    }
}
EOF
    "$SCRIPT"
    # Desired PreToolUse entries are added; existing Skill entry is preserved
    run jq '.hooks.PreToolUse | length' "$HOME/.claude/settings.json"
    [ "$output" -ge 2 ]
    # Verify the existing Skill entry is preserved (not lost during union)
    run jq '.hooks.PreToolUse | map(select(.matcher == "Skill")) | length' "$HOME/.claude/settings.json"
    [ "$output" = "1" ]
    # UserPromptSubmit (not in DESIRED) is preserved
    run jq '.hooks | has("UserPromptSubmit")' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
}

# ---------------------------------------------------------------------------
# Idempotency
# ---------------------------------------------------------------------------

@test "idempotent: running twice produces semantically identical output" {
    # Normalize: sort object keys (-S) and sort all arrays (walk)
    normalize() {
        jq -S 'walk(if type == "array" then sort else . end)' "$1"
    }
    "$SCRIPT"
    FIRST=$(normalize "$HOME/.claude/settings.json")
    "$SCRIPT"
    SECOND=$(normalize "$HOME/.claude/settings.json")
    [ "$FIRST" = "$SECOND" ]
}

@test "notification adapter delegates to agent-attention" {
    install_shared_hooks_home "$HOME"
    mkdir -p "$HOME/.claude/hooks"
    cp "$REPO_ROOT/home/dot_claude/hooks/executable_notification.sh" "$HOME/.claude/hooks/notification.sh"
    chmod +x "$HOME/.claude/hooks/notification.sh"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-attention.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-attention.sh"

    run env HOME="$HOME" "$HOME/.claude/hooks/notification.sh" <<<'{}'
    [ "$status" -eq 0 ]
    [ "$(cat "$CALLS")" = $'Claude Code\nNeeds your attention' ]
    rm -f "$CALLS"
}

@test "stop adapter delegates to agent-finished after elapsed time" {
    install_shared_hooks_home "$HOME"
    mkdir -p "$HOME/.claude/hooks"
    cp "$REPO_ROOT/home/dot_claude/hooks/executable_stop.sh" "$HOME/.claude/hooks/stop.sh"
    chmod +x "$HOME/.claude/hooks/stop.sh"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-finished.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-finished.sh"

    SESSION="claude-stop-$$"
    MARKER_DIR="$(mktemp -d)"
    PAST=$(( $(date +%s) - 15 ))
    printf '%s\n' "$PAST" > "$MARKER_DIR/claude-last-stop-$SESSION"

    run env HOME="$HOME" TMPDIR="$MARKER_DIR" "$HOME/.claude/hooks/stop.sh" <<EOF
{"stop_hook_active":false,"session_id":"$SESSION"}
EOF
    [ "$status" -eq 0 ]
    [ "$(cat "$CALLS")" = $'Claude Code\nFinished' ]
    rm -f "$CALLS"
    rm -rf "$MARKER_DIR"
}

@test "pre-tool-use adapter emits agent-danger on denied Bash command" {
    install_shared_hooks_home "$HOME"
    mkdir -p "$HOME/.claude/hooks"
    cp "$REPO_ROOT/home/dot_claude/hooks/executable_pre-tool-use.sh" "$HOME/.claude/hooks/pre-tool-use.sh"
    chmod +x "$HOME/.claude/hooks/pre-tool-use.sh"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-danger.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-danger.sh"

    run env HOME="$HOME" "$HOME/.claude/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}
EOF

    [ "$status" -eq 2 ]
    [ "$(cat "$CALLS")" = $'Claude Code\nDangerous command blocked' ]
    rm -f "$CALLS"
}

@test "pre-tool-use adapter does not emit agent-danger on shared library failure" {
    install_shared_hooks_home "$HOME"
    mkdir -p "$HOME/.claude/hooks"
    cp "$REPO_ROOT/home/dot_claude/hooks/executable_pre-tool-use.sh" "$HOME/.claude/hooks/pre-tool-use.sh"
    chmod +x "$HOME/.claude/hooks/pre-tool-use.sh"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-danger.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-danger.sh"
    rm -f "$HOME/.agents/hooks/lib/env_policy.sh" "$HOME/.agents/hooks/lib/executable_env_policy.sh"

    run env HOME="$HOME" "$HOME/.claude/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}
EOF

    [ "$status" -eq 2 ]
    printf '%s' "$output" | grep -q 'Blocked: missing shared hook library: env_policy'
    [ ! -s "$CALLS" ]
    rm -f "$CALLS"
}

@test "pre-tool-use adapter preserves sudo warning in stderr" {
    install_shared_hooks_home "$HOME"
    mkdir -p "$HOME/.claude/hooks"
    cp "$REPO_ROOT/home/dot_claude/hooks/executable_pre-tool-use.sh" "$HOME/.claude/hooks/pre-tool-use.sh"
    chmod +x "$HOME/.claude/hooks/pre-tool-use.sh"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-danger.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-danger.sh"

    run env HOME="$HOME" "$HOME/.claude/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"sudo apt-get update"}}
EOF

    [ "$status" -eq 0 ]
    printf '%s' "$output" | grep -q 'Warning: sudo usage detected.'
    [ ! -s "$CALLS" ]
    rm -f "$CALLS"
}
