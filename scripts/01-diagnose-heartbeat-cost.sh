#!/usr/bin/env bash
set -euo pipefail

SINCE="${1:-2026-06-02 21:00}"
STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
SESSIONS_DIR="$STATE_DIR/agents/main/agent/codex-home/sessions"

if ! command -v node >/dev/null 2>&1; then
  echo "node is required" >&2
  exit 1
fi

if [ ! -d "$SESSIONS_DIR" ]; then
  echo "No Codex session directory found: $SESSIONS_DIR" >&2
  exit 1
fi

echo "Scanning sessions newer than: $SINCE"
find "$SESSIONS_DIR" -type f -name '*.jsonl' -newermt "$SINCE" -print0 |
  xargs -0 node -e '
const fs = require("fs");
const files = process.argv.slice(1);
const rows = [];
for (const file of files) {
  let first = null;
  let last = null;
  let count = 0;
  for (const line of fs.readFileSync(file, "utf8").split(/\n/)) {
    if (!line.trim()) continue;
    let o;
    try { o = JSON.parse(line); } catch { continue; }
    if (o.type !== "event_msg" || o.payload?.type !== "token_count") continue;
    const info = o.payload.info || {};
    const usage = info.total_token_usage || {};
    const lastUsage = info.last_token_usage || {};
    const limits = o.payload.rate_limits || {};
    const row = {
      ts: o.timestamp,
      total: usage.total_tokens || 0,
      last: lastUsage.total_tokens || 0,
      primary: limits.primary?.used_percent,
      weekly: limits.secondary?.used_percent
    };
    first ??= row;
    last = row;
    count++;
  }
  if (count > 0) rows.push({ file, count, first, last });
}
rows.sort((a, b) => (b.last.total || 0) - (a.last.total || 0));
for (const r of rows) {
  console.log("");
  console.log(r.file);
  console.log(`  token events: ${r.count}`);
  console.log(`  first: ${r.first.ts} total=${r.first.total} weekly=${r.first.weekly}%`);
  console.log(`  last:  ${r.last.ts} total=${r.last.total} weekly=${r.last.weekly}% lastTurn=${r.last.last}`);
}
'
