#!/bin/bash
# Shared signal entrypoint.

# shellcheck disable=SC1090,SC1091
. "$HOME/.agents/hooks/lib/notify.sh"

emit_agent_signal "${1:-}" "${2:-Agent}" "${3:-}"
