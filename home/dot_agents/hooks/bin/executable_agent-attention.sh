#!/bin/bash
# Shared attention signal wrapper.

exec "$HOME/.agents/hooks/bin/agent-signal.sh" attention "${1:-Agent}" "${2:-Needs your attention}"
