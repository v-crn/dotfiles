#!/bin/bash
# Shared danger signal wrapper.

exec "$HOME/.agents/hooks/bin/agent-signal.sh" danger "${1:-Agent}" "${2:-Dangerous command blocked}"
