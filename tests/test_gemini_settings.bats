#!/usr/bin/env bats

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI_ROOT="$(tr -d '[:space:]' < "$REPO_ROOT/.chezmoiroot")"
SCRIPT="$REPO_ROOT/$CHEZMOI_ROOT/dot_gemini/run_apply-gemini-settings.sh"
HOOKS_DIR="$REPO_ROOT/$CHEZMOI_ROOT/dot_gemini/hooks"

setup() {
    TEST_HOME="$(mktemp -d)"
    mkdir -p "$TEST_HOME/.gemini"
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

install_gemini_hooks_home() {
    local target_home="$1"

    mkdir -p "$target_home/.gemini/hooks"
    cp "$HOOKS_DIR/executable_pre-tool-use.sh" "$target_home/.gemini/hooks/pre-tool-use.sh"
    cp "$HOOKS_DIR/executable_notification.sh" "$target_home/.gemini/hooks/notification.sh"
    cp "$HOOKS_DIR/executable_stop.sh" "$target_home/.gemini/hooks/stop.sh"
    chmod +x \
        "$target_home/.gemini/hooks/pre-tool-use.sh" \
        "$target_home/.gemini/hooks/notification.sh" \
        "$target_home/.gemini/hooks/stop.sh"
}

@test "deployed hooks exist and are executable" {
    install_gemini_hooks_home "$HOME"
    [ -x "$HOME/.gemini/hooks/pre-tool-use.sh" ]
    [ -x "$HOME/.gemini/hooks/notification.sh" ]
    [ -x "$HOME/.gemini/hooks/stop.sh" ]
}

@test "apply script exists and is executable" {
    [ -x "$SCRIPT" ]
}

@test "new install: creates Gemini settings.json" {
    "$SCRIPT"
    [ -f "$HOME/.gemini/settings.json" ]
}

@test "new install: config points to deployed hook adapters" {
    "$SCRIPT"

    run jq -r '.hooks.PreToolUse[0].matcher' "$HOME/.gemini/settings.json"
    [ "$output" = "Bash|Read|Edit|MultiEdit|Write" ]

    run jq -r '.hooks.PreToolUse[0].hooks[0].command' "$HOME/.gemini/settings.json"
    [ "$output" = "~/.gemini/hooks/pre-tool-use.sh" ]

    run jq -r '.hooks.Notification[0].hooks[0].command' "$HOME/.gemini/settings.json"
    [ "$output" = "~/.gemini/hooks/notification.sh" ]

    run jq -r '.hooks.Stop[0].hooks[0].command' "$HOME/.gemini/settings.json"
    [ "$output" = "~/.gemini/hooks/stop.sh" ]
}

@test "existing settings: preserves unrelated keys while updating hooks" {
    cat > "$HOME/.gemini/settings.json" <<'EOF'
{
  "theme": "dark",
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "echo keep-pre"
          }
        ]
      }
    ],
    "OtherEvent": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo keep"
          }
        ]
      }
    ]
  }
}
EOF

    "$SCRIPT"

    run jq -r '.theme' "$HOME/.gemini/settings.json"
    [ "$output" = "dark" ]

    run jq -r '.hooks.PreToolUse[] | select(.matcher == "Skill") | .hooks[0].command' "$HOME/.gemini/settings.json"
    [ "$output" = "echo keep-pre" ]

    run jq -r '.hooks.PreToolUse[] | select(.matcher == "Bash|Read|Edit|MultiEdit|Write") | .hooks[0].command' "$HOME/.gemini/settings.json"
    [ "$output" = "~/.gemini/hooks/pre-tool-use.sh" ]

    run jq -r '.hooks.OtherEvent[0].hooks[0].command' "$HOME/.gemini/settings.json"
    [ "$output" = "echo keep" ]

    run jq -r '.hooks.PreToolUse | length' "$HOME/.gemini/settings.json"
    [ "$output" = "2" ]
    [ "$status" -eq 0 ]
}

@test "apply script is idempotent for managed hooks" {
    cat > "$HOME/.gemini/settings.json" <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Skill",
        "hooks": [
          {
            "type": "command",
            "command": "echo keep-pre"
          }
        ]
      }
    ]
  }
}
EOF

    "$SCRIPT"
    FIRST="$(cat "$HOME/.gemini/settings.json")"
    "$SCRIPT"
    SECOND="$(cat "$HOME/.gemini/settings.json")"

    [ "$FIRST" = "$SECOND" ]
}

@test "pre-tool-use adapter blocks MultiEdit of .env.local" {
    install_shared_hooks_home "$HOME"
    install_gemini_hooks_home "$HOME"

    run env HOME="$HOME" "$HOME/.gemini/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"MultiEdit","tool_input":{"file_path":"/project/.env.local"}}
EOF

    [ "$status" -eq 2 ]
}

@test "pre-tool-use adapter allows Bash payload without file_path" {
    install_shared_hooks_home "$HOME"
    install_gemini_hooks_home "$HOME"
    mkdir -p "$HOME/.agents/hooks/bin"
    cat > "$HOME/.agents/hooks/bin/check-preflight.sh" <<'EOF'
#!/bin/bash
printf '%s|%s|%s\n' "$1" "$2" "$3"
EOF
    chmod +x "$HOME/.agents/hooks/bin/check-preflight.sh"

    run env HOME="$HOME" "$HOME/.gemini/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"echo hi"}}
EOF

    [ "$status" -eq 0 ]
    [ "$output" = "Bash||echo hi" ]
}

@test "pre-tool-use adapter allows file tool payload without command" {
    install_shared_hooks_home "$HOME"
    install_gemini_hooks_home "$HOME"
    mkdir -p "$HOME/.agents/hooks/bin"
    cat > "$HOME/.agents/hooks/bin/check-preflight.sh" <<'EOF'
#!/bin/bash
printf '%s|%s|%s\n' "$1" "$2" "$3"
EOF
    chmod +x "$HOME/.agents/hooks/bin/check-preflight.sh"

    run env HOME="$HOME" "$HOME/.gemini/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Read","tool_input":{"file_path":"/project/.env"}}
EOF

    [ "$status" -eq 0 ]
    [ "$output" = "Read|/project/.env|" ]
}

@test "notification adapter delegates to agent-attention" {
    install_shared_hooks_home "$HOME"
    install_gemini_hooks_home "$HOME"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-attention.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-attention.sh"

    run env HOME="$HOME" "$HOME/.gemini/hooks/notification.sh" <<<'{}'
    [ "$status" -eq 0 ]
    [ "$(cat "$CALLS")" = $'Gemini\nNeeds your attention' ]
    rm -f "$CALLS"
}

@test "stop adapter delegates to agent-finished" {
    install_shared_hooks_home "$HOME"
    install_gemini_hooks_home "$HOME"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-finished.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-finished.sh"

    run env HOME="$HOME" "$HOME/.gemini/hooks/stop.sh" <<<'{}'
    [ "$status" -eq 0 ]
    [ "$(cat "$CALLS")" = $'Gemini\nFinished' ]
    rm -f "$CALLS"
}

@test "pre-tool-use adapter emits agent-danger on denied Bash command" {
    install_shared_hooks_home "$HOME"
    install_gemini_hooks_home "$HOME"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-danger.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-danger.sh"

    run env HOME="$HOME" "$HOME/.gemini/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}
EOF

    [ "$status" -eq 2 ]
    [ "$(cat "$CALLS")" = $'Gemini\nDangerous command blocked' ]
    rm -f "$CALLS"
}

@test "pre-tool-use adapter does not emit agent-danger on shared library failure" {
    install_shared_hooks_home "$HOME"
    install_gemini_hooks_home "$HOME"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-danger.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-danger.sh"
    rm -f "$HOME/.agents/hooks/lib/env_policy.sh" "$HOME/.agents/hooks/lib/executable_env_policy.sh"

    run env HOME="$HOME" "$HOME/.gemini/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}
EOF

    [ "$status" -eq 2 ]
    printf '%s' "$output" | grep -q 'Blocked: missing shared hook library: env_policy'
    [ ! -s "$CALLS" ]
    rm -f "$CALLS"
}

@test "pre-tool-use adapter preserves sudo warning in stderr" {
    install_shared_hooks_home "$HOME"
    install_gemini_hooks_home "$HOME"
    CALLS="$(mktemp)"
    cat > "$HOME/.agents/hooks/bin/agent-danger.sh" <<EOF
#!/bin/bash
printf '%s\n' "\$@" >> "$CALLS"
EOF
    chmod +x "$HOME/.agents/hooks/bin/agent-danger.sh"

    run env HOME="$HOME" "$HOME/.gemini/hooks/pre-tool-use.sh" <<'EOF'
{"tool_name":"Bash","tool_input":{"command":"sudo apt-get update"}}
EOF

    [ "$status" -eq 0 ]
    printf '%s' "$output" | grep -q 'Warning: sudo usage detected.'
    [ ! -s "$CALLS" ]
    rm -f "$CALLS"
}
