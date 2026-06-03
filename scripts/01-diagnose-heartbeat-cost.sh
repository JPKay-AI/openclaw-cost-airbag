#!/usr/bin/env bash
set -euo pipefail

SINCE="${1:-2026-06-02 21:00}"
STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
AGENTS_DIR="$STATE_DIR/agents"

if ! command -v node >/dev/null 2>&1; then
  echo "node is required" >&2
  exit 1
fi

if [ ! -d "$AGENTS_DIR" ]; then
  echo "No OpenClaw agents directory found: $AGENTS_DIR" >&2
  exit 1
fi

echo "Scanning sessions newer than: $SINCE"
node - "$AGENTS_DIR" "$SINCE" <<'NODE'
const fs = require("fs");
const path = require("path");

const root = process.argv[2];
const sinceArg = process.argv[3];
const sinceMs = Date.parse(sinceArg);
if (Number.isNaN(sinceMs)) {
  console.error(`Could not parse start time: ${sinceArg}`);
  process.exit(1);
}

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "node_modules" || entry.name === ".git") continue;
      walk(full, out);
    } else if (entry.isFile() && entry.name.endsWith(".jsonl")) {
      const stat = fs.statSync(full);
      if (stat.mtimeMs >= sinceMs) out.push(full);
    }
  }
  return out;
}

function classify(file) {
  if (file.includes("/codex-home/sessions/")) return "codex";
  if (file.includes("/sessions/")) return "openclaw-session";
  return "jsonl";
}

const files = walk(root);
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
  if (count > 0) rows.push({ file, kind: classify(file), count, first, last });
}
rows.sort((a, b) => (b.last.total || 0) - (a.last.total || 0));
if (rows.length === 0) {
  console.log("No token_count events found in recent JSONL logs.");
  process.exit(0);
}
for (const r of rows) {
  console.log("");
  console.log(r.file);
  console.log(`  kind: ${r.kind}`);
  console.log(`  token events: ${r.count}`);
  console.log(`  first: ${r.first.ts} total=${r.first.total} weekly=${r.first.weekly}%`);
  console.log(`  last:  ${r.last.ts} total=${r.last.total} weekly=${r.last.weekly}% lastTurn=${r.last.last}`);
}
NODE
