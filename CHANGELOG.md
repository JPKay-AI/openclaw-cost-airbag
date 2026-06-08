# Changelog

## v0.3

- Added `scripts/04-diagnose-background-runaways.sh` for read-only checks of
  short-interval OpenClaw-related LaunchAgents, log growth, suspicious high-CPU
  hook/node/device processes, and memory index readiness.
- Extended `scripts/03-verify-cost-airbag.sh` to include the background
  runaway check.
- Updated README recovery guidance for non-heartbeat local loops.

## v0.2

- Broadened diagnosis from a fixed Codex session path to recursive OpenClaw
  agent JSONL log scanning.
- Added provider-neutral README wording.
- Clarified that heartbeat shutdown is OpenClaw-level, while diagnosis depends
  on compatible `token_count` events.

## v0.1

- Initial toolkit with diagnosis, heartbeat disable, and verification scripts.
