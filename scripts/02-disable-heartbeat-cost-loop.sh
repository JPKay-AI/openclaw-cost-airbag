#!/usr/bin/env bash
set -euo pipefail

CONFIG="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$CONFIG.bak-$STAMP-before-heartbeat-cost-airbag"

if ! command -v openclaw >/dev/null 2>&1; then
  echo "openclaw CLI is required" >&2
  exit 1
fi

if [ ! -f "$CONFIG" ]; then
  echo "Config not found: $CONFIG" >&2
  exit 1
fi

cp "$CONFIG" "$BACKUP"
echo "Backup: $BACKUP"

cat <<'JSON' | openclaw config patch --stdin
{
  "agents": {
    "defaults": {
      "heartbeat": {
        "every": "",
        "includeSystemPromptSection": false,
        "ackMaxChars": 20,
        "suppressToolErrorWarnings": true,
        "timeoutSeconds": 20,
        "lightContext": true,
        "skipWhenBusy": true
      }
    }
  }
}
JSON

openclaw config validate
echo ""
echo "Heartbeat cost loop disabled in config."
echo "Restart the gateway to apply:"
echo "  openclaw gateway restart"
echo ""
echo "If restart fails because the port is busy on macOS:"
echo "  launchctl kickstart -k gui/\$UID/ai.openclaw.gateway"
