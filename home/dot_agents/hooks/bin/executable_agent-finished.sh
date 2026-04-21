#!/bin/bash
# Shared finished signal wrapper.

exec "$HOME/.agents/hooks/bin/agent-signal.sh" finished "${1:-Agent}" "${2:-Finished}"
