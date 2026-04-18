#!/usr/bin/env bats
# Tests for home/.chezmoiscripts/run_always_link-agent-skills.sh
# and home/dot_agents/skills/ctx7-read-official-docs

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CHEZMOI_ROOT="$(tr -d '[:space:]' < "$REPO_ROOT/.chezmoiroot")"
SCRIPT="$REPO_ROOT/$CHEZMOI_ROOT/.chezmoiscripts/run_always_link-agent-skills.sh"
CTX7_SKILL="$REPO_ROOT/$CHEZMOI_ROOT/dot_agents/skills/ctx7-read-official-docs/SKILL.md"

setup() {
    TEST_HOME="$(mktemp -d)"
    mkdir -p "$TEST_HOME/.agents/skills/skill-alpha"
    mkdir -p "$TEST_HOME/.agents/skills/skill-beta"
    export HOME="$TEST_HOME"
}

teardown() {
    rm -rf "$TEST_HOME"
}

# ---------------------------------------------------------------------------
# Script metadata
# ---------------------------------------------------------------------------

@test "link script exists" {
    [ -f "$SCRIPT" ]
}

@test "link script is executable" {
    [ -x "$SCRIPT" ]
}

# ---------------------------------------------------------------------------
# Claude Code: ~/.claude/skills/
# ---------------------------------------------------------------------------

@test "creates ~/.claude/skills/ if absent" {
    "$SCRIPT"
    [ -d "$HOME/.claude/skills" ]
}

@test "creates symlinks for all agent skills in ~/.claude/skills/" {
    "$SCRIPT"
    [ -L "$HOME/.claude/skills/skill-alpha" ]
    [ -L "$HOME/.claude/skills/skill-beta" ]
}

@test "claude symlink targets ~/.agents/skills/ via relative path" {
    "$SCRIPT"
    target="$(readlink "$HOME/.claude/skills/skill-alpha")"
    [ "$target" = "../../.agents/skills/skill-alpha" ]
}

@test "claude symlink resolves to the actual skill directory" {
    "$SCRIPT"
    [ -d "$HOME/.claude/skills/skill-alpha" ]
}

# ---------------------------------------------------------------------------
# Gemini CLI: ~/.gemini/skills/
# ---------------------------------------------------------------------------

@test "creates ~/.gemini/skills/ if absent" {
    "$SCRIPT"
    [ -d "$HOME/.gemini/skills" ]
}

@test "creates symlinks for all agent skills in ~/.gemini/skills/" {
    "$SCRIPT"
    [ -L "$HOME/.gemini/skills/skill-alpha" ]
    [ -L "$HOME/.gemini/skills/skill-beta" ]
}

@test "gemini symlink targets ~/.agents/skills/ via relative path" {
    "$SCRIPT"
    target="$(readlink "$HOME/.gemini/skills/skill-alpha")"
    [ "$target" = "../../.agents/skills/skill-alpha" ]
}

# ---------------------------------------------------------------------------
# Idempotency
# ---------------------------------------------------------------------------

@test "running script twice does not error" {
    "$SCRIPT"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
}

@test "running script twice does not duplicate symlinks" {
    "$SCRIPT"
    "$SCRIPT"
    count="$(find "$HOME/.claude/skills" -maxdepth 1 -name "skill-alpha" | wc -l)"
    [ "$count" -eq 1 ]
}

# ---------------------------------------------------------------------------
# Stale symlink cleanup
# ---------------------------------------------------------------------------

@test "removes stale symlinks in ~/.claude/skills/" {
    mkdir -p "$HOME/.claude/skills"
    ln -s "../../.agents/skills/ghost" "$HOME/.claude/skills/ghost"
    "$SCRIPT"
    [ ! -L "$HOME/.claude/skills/ghost" ]
}

@test "removes stale symlinks in ~/.gemini/skills/" {
    mkdir -p "$HOME/.gemini/skills"
    ln -s "../../.agents/skills/ghost" "$HOME/.gemini/skills/ghost"
    "$SCRIPT"
    [ ! -L "$HOME/.gemini/skills/ghost" ]
}

@test "does nothing when ~/.agents/skills/ is absent" {
    rm -rf "$TEST_HOME/.agents/skills"
    run "$SCRIPT"
    [ "$status" -eq 0 ]
    [ ! -d "$TEST_HOME/.claude/skills" ]
    [ ! -d "$TEST_HOME/.gemini/skills" ]
}

# ---------------------------------------------------------------------------
# ctx7-read-official-docs skill
# ---------------------------------------------------------------------------

@test "ctx7 skill file exists in source" {
    [ -f "$CTX7_SKILL" ]
}

@test "ctx7 skill has name frontmatter" {
    grep -q '^name:' "$CTX7_SKILL"
}

@test "ctx7 skill has description frontmatter" {
    grep -q '^description:' "$CTX7_SKILL"
}

@test "ctx7 skill description begins with a recognised trigger verb" {
    # Extract first line of description value (may be multi-line with |)
    desc_line="$(awk '/^description:/{found=1; next} found && /^  /{print; exit} found && !/^  /{exit}' "$CTX7_SKILL")"
    # Fallback: single-line description on same line as key
    if [ -z "$desc_line" ]; then
        desc_line="$(grep '^description:' "$CTX7_SKILL" | sed 's/^description: *//')"
    fi
    echo "desc: $desc_line"
    echo "$desc_line" | grep -qi 'retrieves\|use when\|use this'
}
