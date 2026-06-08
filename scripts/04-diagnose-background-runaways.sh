#!/usr/bin/env bash
set -euo pipefail

SAMPLE_SECONDS="${SAMPLE_SECONDS:-5}"
CPU_THRESHOLD="${CPU_THRESHOLD:-50}"
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"

usage() {
  cat <<'USAGE'
Usage:
  scripts/04-diagnose-background-runaways.sh [--sample-seconds <n>] [--cpu-threshold <percent>]

Read-only checks for local OpenClaw-related background loops:
  - LaunchAgents with short StartInterval, KeepAlive, or RunAtLoad
  - OpenClaw/Codex/Thora/Cockpit log files that grow during a short sample
  - suspicious high-CPU OpenClaw hook/node/device processes
  - Memory index status, when the OpenClaw CLI supports it

Exit codes:
  0  no suspicious findings
  1  suspicious findings detected
  2  invalid usage or local command failure
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --sample-seconds)
      shift
      SAMPLE_SECONDS="${1:-}"
      ;;
    --cpu-threshold)
      shift
      CPU_THRESHOLD="${1:-}"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift || true
done

case "$SAMPLE_SECONDS" in
  ''|*[!0-9]*)
    echo "--sample-seconds must be a non-negative integer" >&2
    exit 2
    ;;
esac

case "$CPU_THRESHOLD" in
  ''|*[!0-9.]*)
    echo "--cpu-threshold must be numeric" >&2
    exit 2
    ;;
esac

section() {
  printf '\n## %s\n\n' "$1"
}

is_openclaw_path() {
  case "$1" in
    *openclaw*|*OpenClaw*|*codex*|*Codex*|*thora*|*Thora*|*cockpit*|*Cockpit*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

find_log_files() {
  for root in \
    "$OPENCLAW_HOME" \
    "$HOME/Library/Logs/openclaw" \
    "$HOME/.openclaw/workspace/tmp/logs" \
    "$HOME/.openclaw/workspace/projects/openclaw-learning-lab/tmp"; do
    [ -d "$root" ] || continue
    find "$root" -type f \( -name '*.log' -o -name '*.out' -o -name '*.err' \) 2>/dev/null
  done | while IFS= read -r file; do
    is_openclaw_path "$file" && printf '%s\n' "$file"
  done | sort -u
}

section "LaunchAgents"

launchagent_findings=0
if command -v python3 >/dev/null 2>&1; then
  DISABLED_LAUNCHD_LABELS="$(
    if command -v launchctl >/dev/null 2>&1; then
      launchctl print-disabled "gui/$(id -u)" 2>/dev/null | awk -F '"' '/=> disabled/ {print $2}'
    fi
  )"
  export DISABLED_LAUNCHD_LABELS
  if ! python3 - "$HOME/Library/LaunchAgents" "/Library/LaunchAgents" <<'PY'
import os
import plistlib
import sys

roots = sys.argv[1:]
terms = ("openclaw", "codex", "thora", "cockpit")
loop_terms = ("hook", "cockpit", "poller", "bridge", "relay")
disabled = set(filter(None, os.environ.get("DISABLED_LAUNCHD_LABELS", "").splitlines()))

def relevant(text):
    return any(term in text.lower() for term in terms)

rows = []
for root in roots:
    if not os.path.isdir(root):
        continue
    for name in sorted(os.listdir(root)):
        if not name.endswith(".plist"):
            continue
        path = os.path.join(root, name)
        if not relevant(path):
            continue
        try:
            with open(path, "rb") as f:
                data = plistlib.load(f)
        except Exception as exc:
            rows.append((path, "parse-error", str(exc)))
            continue
        label = data.get("Label", name)
        if label in disabled:
            continue
        start_interval = data.get("StartInterval")
        keep_alive = data.get("KeepAlive")
        run_at_load = data.get("RunAtLoad")
        stdout = data.get("StandardOutPath", "")
        stderr = data.get("StandardErrorPath", "")
        reasons = []
        label_text = f"{label} {path}".lower()
        if isinstance(start_interval, int) and 0 < start_interval <= 60:
            reasons.append(f"short StartInterval={start_interval}s")
        if keep_alive and any(term in label_text for term in loop_terms):
            reasons.append(f"KeepAlive={keep_alive}")
        if run_at_load and any(term in label_text for term in loop_terms):
            reasons.append("RunAtLoad=true")
        if reasons and stdout and relevant(stdout):
            reasons.append(f"stdout={stdout}")
        if reasons and stderr and relevant(stderr):
            reasons.append(f"stderr={stderr}")
        if reasons:
            rows.append((path, label, "; ".join(reasons)))

if not rows:
    print("No suspicious OpenClaw-related LaunchAgents found.")
else:
    for path, label, reason in rows:
        print(f"SUSPICIOUS {label}")
        print(f"  path: {path}")
        print(f"  reason: {reason}")
    sys.exit(1)
PY
  then
    launchagent_findings=1
  fi
else
  echo "python3 not available; skipping LaunchAgent plist inspection."
fi

section "Log Growth"

log_findings=0
tmp_before="$(mktemp)"
tmp_after="$(mktemp)"
trap 'rm -f "$tmp_before" "$tmp_after"' EXIT

while IFS= read -r file; do
  size="$(stat -f '%z' "$file" 2>/dev/null || stat -c '%s' "$file" 2>/dev/null || true)"
  [ -n "$size" ] && printf '%s\t%s\n' "$file" "$size"
done < <(find_log_files) >"$tmp_before"

if [ "$SAMPLE_SECONDS" -gt 0 ]; then
  sleep "$SAMPLE_SECONDS"
fi

while IFS= read -r file; do
  size="$(stat -f '%z' "$file" 2>/dev/null || stat -c '%s' "$file" 2>/dev/null || true)"
  [ -n "$size" ] && printf '%s\t%s\n' "$file" "$size"
done < <(find_log_files) >"$tmp_after"

if [ ! -s "$tmp_before" ]; then
  echo "No OpenClaw-related log files found."
else
  awk -F '\t' '
    NR == FNR { before[$1] = $2; next }
    ($1 in before) && ($2 > before[$1]) {
      printf "SUSPICIOUS log grew: %s (%s -> %s bytes)\n", $1, before[$1], $2
      found = 1
    }
    END {
      if (!found) print "No OpenClaw-related logs grew during the sample."
      exit found ? 1 : 0
    }
  ' "$tmp_before" "$tmp_after" || log_findings=1
fi

section "Processes"

process_findings=0
ps -axo pid,pcpu,pmem,etime,command \
  | awk -v threshold="$CPU_THRESHOLD" '
      BEGIN { found = 0 }
      /openclaw-hooks|openclaw-nodes|openclaw-devices|native-hook|codex app-server|openclaw\/dist\/index.js gateway/ && $2 + 0 >= threshold {
        print "SUSPICIOUS high CPU: " $0
        found = 1
      }
      END {
        if (!found) print "No suspicious OpenClaw-related high-CPU processes."
        exit found ? 1 : 0
      }
    ' || process_findings=1

section "Memory Index"

memory_findings=0
if command -v openclaw >/dev/null 2>&1; then
  if openclaw memory status --index 2>/dev/null | awk '
      /Dirty: yes/ { dirty = 1 }
      /Vector store: ready/ { vector = 1 }
      /FTS: ready/ { fts = 1 }
      /Indexed:/ { indexed = $0 }
      END {
        if (indexed) print indexed
        print "Vector store ready: " (vector ? "yes" : "no")
        print "FTS ready: " (fts ? "yes" : "no")
        print "Dirty: " (dirty ? "yes" : "no")
        exit (dirty || !vector || !fts) ? 1 : 0
      }
    '; then
    true
  else
    memory_findings=1
  fi
else
  echo "openclaw CLI not available; skipping memory index status."
fi

if [ "$launchagent_findings" -ne 0 ] || [ "$log_findings" -ne 0 ] || [ "$process_findings" -ne 0 ] || [ "$memory_findings" -ne 0 ]; then
  exit 1
fi

exit 0
