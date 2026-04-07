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

@test "new install: does not include hooks" {
    "$SCRIPT"
    run jq 'has("hooks")' "$HOME/.claude/settings.json"
    [ "$output" = "false" ]
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

@test "merge: preserves existing hooks" {
    cat > "$HOME/.claude/settings.json" <<'EOF'
{
    "hooks": {
        "PreToolUse": [{"_tag": "ccstatusline-managed", "type": "command", "command": "npx ccstatusline"}]
    }
}
EOF
    "$SCRIPT"
    run jq '.hooks.PreToolUse | length' "$HOME/.claude/settings.json"
    [ "$output" = "1" ]
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
