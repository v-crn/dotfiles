#!/bin/bash
# Post-turn notification hook for OpenAI Codex CLI.
# Referenced in config.toml: notify = ["~/.codex/hooks/notify.sh"]
# shellcheck disable=SC1090,SC1091
. ~/.agents/hooks/lib/notify.sh

send_notification "Codex" "Finished"
