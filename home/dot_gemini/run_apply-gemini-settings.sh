#!/bin/sh
# Apply Gemini settings, rewriting only the managed hook block.

DESIRED=$(cat <<'EOF'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|Read|Edit|MultiEdit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "~/.gemini/hooks/pre-tool-use.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.gemini/hooks/notification.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.gemini/hooks/stop.sh"
          }
        ]
      }
    ]
  }
}
EOF
)

TARGET="$HOME/.gemini/settings.json"

if ! command -v jq >/dev/null 2>&1; then
    printf 'Warning: jq not found. Skipping gemini settings merge.\n' >&2
    exit 0
fi

if [ ! -f "$TARGET" ]; then
    mkdir -p "$(dirname "$TARGET")"
    printf '%s\n' "$DESIRED" > "$TARGET"
    exit 0
fi

CURRENT="$(cat "$TARGET")"
if ! MERGED="$(printf '%s' "$CURRENT" | jq --argjson desired "$DESIRED" '
    .hooks = (
        (.hooks // {}) as $current
        | reduce ($desired.hooks | keys[]) as $event ($current;
            .[$event] = (
                reduce ($desired.hooks[$event] // [])[] as $item ((.[ $event ] // []);
                    if index($item) then . else . + [$item] end
                )
            )
        )
    )
')"; then
    printf 'Error: jq failed. Aborting merge.\n' >&2
    exit 1
fi

printf '%s\n' "$MERGED" > "$TARGET"
