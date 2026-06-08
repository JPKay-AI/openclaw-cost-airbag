#!/usr/bin/env bash
set -euo pipefail

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw CLI is required" >&2
  exit 1
fi

echo "Heartbeat config:"
openclaw config get agents.defaults.heartbeat || true

echo ""
echo "Status:"
openclaw status | sed -n '/Gateway service/p;/Heartbeat/p;/Sessions/p'

echo ""
echo "Background runaway check:"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/04-diagnose-background-runaways.sh" --sample-seconds 2
