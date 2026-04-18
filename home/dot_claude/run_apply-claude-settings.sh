#!/bin/sh
# Apply Claude Code settings, merging with any existing ~/.claude/settings.json.
#
# Merge strategy per key:
#   Overwrite:  env, language, statusLine, sandbox (scalars),
#               enableAllProjectMcpServers,
#               permissions.disableBypassPermissionsMode
#   Union:      sandbox.excludedCommands, sandbox.network.allowedHosts,
#               permissions.allow, permissions.deny
#   Preserve:   enabledPlugins (not present in desired — kept from existing)
#   Union/event: hooks (desired events merged into existing; other events preserved)

# -----------------------------------------------------------------------
# Desired settings (edit this section to update settings)
# -----------------------------------------------------------------------
DESIRED=$(cat <<'EOF'
{
    "env": {
        "MAX_THINKING_TOKENS": "12000",
        "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "60",
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
        "VERCEL_PLUGIN_TELEMETRY": "off"
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
    },
    "hooks": {
        "PreToolUse": [
            {
                "matcher": "Bash|Read|Edit|Write",
                "hooks": [{"type": "command", "command": "~/.claude/hooks/pre-tool-use.sh"}]
            }
        ],
        "Notification": [
            {
                "matcher": "",
                "hooks": [{"type": "command", "command": "~/.claude/hooks/notification.sh"}]
            }
        ],
        "Stop": [
            {
                "hooks": [{"type": "command", "command": "~/.claude/hooks/stop.sh"}]
            }
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
    TMP=$(mktemp "${TARGET}.tmp.XXXXXX")
    if ! { printf '%s\n' "$DESIRED" > "$TMP" && mv "$TMP" "$TARGET"; }; then
        rm -f "$TMP"; exit 1
    fi
    exit 0
fi

# Existing file: merge per-key
CURRENT=$(cat "$TARGET")

MERGED=$(printf '%s' "$CURRENT" | jq --argjson d "$DESIRED" '
  # enabledPlugins is intentionally not touched — preserved from existing file
  # hooks: for each event key in desired, union arrays into existing; other events preserved
  .hooks = (
    ($d.hooks // {}) as $dh |
    (.hooks // {}) as $ch |
    ($dh | keys) as $dkeys |
    reduce $dkeys[] as $event (
      $ch;
      .[$event] = (
        ((.[$event] // []) + $dh[$event]) | unique
      )
    )
  ) |
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

if [ -z "$MERGED" ]; then
    echo "Error: jq failed to process $TARGET. Aborting merge." >&2
    exit 1
fi

TMP=$(mktemp "${TARGET}.tmp.XXXXXX")
if ! { printf '%s\n' "$MERGED" > "$TMP" && mv "$TMP" "$TARGET"; }; then
    rm -f "$TMP"; exit 1
fi
