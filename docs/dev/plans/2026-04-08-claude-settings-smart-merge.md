# Claude settings.json Smart Merge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `home/dot_claude/settings.json` with a chezmoi run script that merges desired settings into `~/.claude/settings.json` on every `chezmoi apply`, preserving user-managed fields.

**Architecture:** A single `run_apply-claude-settings.sh` script embeds the desired JSON as a heredoc, reads the current deployed file, and uses `jq` to merge per-key strategies. Scalar keys are overwritten; array keys (`permissions.allow`, `permissions.deny`, `sandbox.excludedCommands`, `sandbox.network.allowedHosts`) are unioned; `hooks` and `enabledPlugins` are preserved entirely from the deployed file.

**Tech Stack:** POSIX sh, jq, bats-core (tests)

---

## Task 1: Create the merge script

**Files:**

- Create: `home/dot_claude/run_apply-claude-settings.sh`

- [ ] **Step 1: Write the script**

Create `home/dot_claude/run_apply-claude-settings.sh` with the following content:

```sh
#!/bin/sh
# Apply Claude Code settings, merging with any existing ~/.claude/settings.json.
#
# Merge strategy per key:
#   Overwrite:  env, language, statusLine, sandbox (scalars),
#               enableAllProjectMcpServers,
#               permissions.disableBypassPermissionsMode
#   Union:      sandbox.excludedCommands, sandbox.network.allowedHosts,
#               permissions.allow, permissions.deny
#   Preserve:   hooks, enabledPlugins (not present in desired — kept from existing)

# -----------------------------------------------------------------------
# Desired settings (edit this section to update settings)
# -----------------------------------------------------------------------
DESIRED=$(cat <<'EOF'
{
    "env": {
        "MAX_THINKING_TOKENS": "12000",
        "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "60",
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
    },
    "language": "Japanese",
    "statusLine": {
        "type": "command",
        "command": "npx -y ccstatusline@latest",
        "padding": 0
    },
    "sandbox": {
        "enabled": true,
        "autoAllowBashIfSandboxed": true,
        "excludedCommands": [
            "git",
            "docker"
        ],
        "network": {
            "allowedHosts": [
                "api.github.com",
                "api.anthropic.com",
                "claude.ai",
                "claude.com",
                "platform.claude.com",
                "mcp-proxy.anthropic.com",
                "http-intake.logs.us5.datadoghq.com",
                "context7.com",
                "generativelanguage.googleapis.com",
                "api.tavily.com",
                "auth.tavily.com"
            ]
        }
    },
    "enableAllProjectMcpServers": false,
    "hooks": {},
    "permissions": {
        "disableBypassPermissionsMode": "disable",
        "deny": [
            "Read(.env)",
            "Bash(sudo *)",
            "Bash(git push --force *)",
            "Bash(git reset --hard *)"
        ],
        "allow": [
            "Read(.env.example)",
            "WebFetch(domain:api.github.com)",
            "WebFetch(domain:api.anthropic.com)",
            "WebFetch(domain:mcp-proxy.anthropic.com)",
            "WebFetch(domain:http-intake.logs.us5.datadoghq.com)",
            "WebFetch(domain:context7.com)",
            "WebFetch(domain:github.com)",
            "WebFetch(domain:pypi.org)",
            "Bash(markdownlint-cli2 *)",
            "Bash(grep:*)",
            "Bash(hadolint *)",
            "Bash(shellcheck *)",
            "Bash(bats:*)",
            "WebFetch",
            "WebSearch",
            "Bash(echo *)",
            "Bash(which *)",
            "Bash(ls *)",
            "Bash(wc *)",
            "Bash(jq *)",
            "Bash(git status)",
            "Bash(git diff *)",
            "Bash(git log *)",
            "Bash(git branch *)",
            "Bash(git switch *)",
            "Bash(git add *)",
            "Bash(git commit *)",
            "Bash(git stash *)",
            "Bash(git show *)",
            "Bash(git rev-parse *)",
            "Bash(git merge-base *)",
            "Bash(git fetch *)",
            "Bash(git pull *)",
            "Bash(gh issue *)",
            "Bash(gh pr view *)",
            "Bash(gh pr list *)",
            "Bash(gh pr checks *)",
            "Bash(gh api *)",
            "Bash(gemini *)",
            "Bash(tvly *)"
        ]
    }
}
EOF
)

# -----------------------------------------------------------------------
# Merge logic (rarely needs editing)
# -----------------------------------------------------------------------
TARGET="$HOME/.claude/settings.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "Warning: jq not found. Skipping claude settings merge." >&2
    exit 0
fi

# New install: write desired settings as-is
if [ ! -f "$TARGET" ]; then
    mkdir -p "$(dirname "$TARGET")"
    printf '%s\n' "$DESIRED" > "$TARGET"
    exit 0
fi

# Existing file: merge per-key
CURRENT=$(cat "$TARGET")

MERGED=$(printf '%s' "$CURRENT" | jq --argjson d "$DESIRED" '
  . as $cur |
  $cur |
  .env = $d.env |
  .language = $d.language |
  .statusLine = $d.statusLine |
  .sandbox.enabled = $d.sandbox.enabled |
  .sandbox.autoAllowBashIfSandboxed = $d.sandbox.autoAllowBashIfSandboxed |
  .sandbox.excludedCommands = (
    ((.sandbox.excludedCommands // []) + ($d.sandbox.excludedCommands // []))
    | unique
  ) |
  .sandbox.network.allowedHosts = (
    ((.sandbox.network.allowedHosts // []) + ($d.sandbox.network.allowedHosts // []))
    | unique
  ) |
  .enableAllProjectMcpServers = $d.enableAllProjectMcpServers |
  .permissions.disableBypassPermissionsMode = $d.permissions.disableBypassPermissionsMode |
  .permissions.allow = (
    ((.permissions.allow // []) + ($d.permissions.allow // []))
    | unique
  ) |
  .permissions.deny = (
    ((.permissions.deny // []) + ($d.permissions.deny // []))
    | unique
  )
')

printf '%s\n' "$MERGED" > "$TARGET"
```

- [ ] **Step 2: Make the script executable**

```bash
chmod +x home/dot_claude/run_apply-claude-settings.sh
```

Verify:

```bash
ls -l home/dot_claude/run_apply-claude-settings.sh
```

Expected: `-rwxr-xr-x` (execute bit set)

---

## Task 2: Delete the old settings.json

**Files:**

- Delete: `home/dot_claude/settings.json`

- [ ] **Step 1: Remove the file**

```bash
git rm home/dot_claude/settings.json
```

Expected output: `rm 'home/dot_claude/settings.json'`

---

## Task 3: Write bats tests

**Files:**

- Create: `tests/test_claude_settings.bats`

- [ ] **Step 1: Write the test file**

Create `tests/test_claude_settings.bats`:

```bash
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

@test "new install: hooks is empty object" {
    "$SCRIPT"
    run jq '.hooks' "$HOME/.claude/settings.json"
    [ "$output" = "{}" ]
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
    # Local addition preserved
    run jq -r '.permissions.allow | contains(["Bash(npm *)"])' "$HOME/.claude/settings.json"
    [ "$output" = "true" ]
    # No duplicates for overlapping entry
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

@test "idempotent: running twice produces identical output" {
    "$SCRIPT"
    FIRST=$(cat "$HOME/.claude/settings.json")
    "$SCRIPT"
    SECOND=$(cat "$HOME/.claude/settings.json")
    [ "$FIRST" = "$SECOND" ]
}
```

- [ ] **Step 2: Run the tests to verify they fail before implementation**

```bash
bats tests/test_claude_settings.bats
```

Expected: script existence tests fail (file not yet created).

---

## Task 4: Verify and commit

- [ ] **Step 1: Run all tests**

```bash
bats tests/
```

Expected: all tests pass, including `test_claude_settings.bats`.

- [ ] **Step 2: Verify script runs correctly against current ~/.claude/settings.json**

```bash
bash home/dot_claude/run_apply-claude-settings.sh
diff <(jq -S . ~/.claude/settings.json) <(jq -S . ~/.claude/settings.json)
```

Manually inspect `~/.claude/settings.json` and confirm:

- `language` is `"Japanese"`
- `enabledPlugins` is preserved
- `hooks` is preserved
- no duplicates in `permissions.allow`

- [ ] **Step 3: Commit**

```bash
git add home/dot_claude/run_apply-claude-settings.sh tests/test_claude_settings.bats
git commit -m "feat: replace settings.json with smart-merge run script"
```
