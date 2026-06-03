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
