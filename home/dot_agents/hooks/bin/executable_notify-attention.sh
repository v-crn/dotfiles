#!/bin/bash
# Shared attention notification hook entrypoint.

# shellcheck disable=SC1090,SC1091
. ~/.agents/hooks/lib/notify.sh

send_notification "${1:-Agent}" "${2:-Needs your attention}"
