# OpenClaw Cost Airbag

Small operational scripts for diagnosing and stopping accidental high-frequency
OpenClaw heartbeat/model runs.

## Why

Agent runtimes can become expensive when background wakeups repeatedly start
large-context model turns. A 30 minute heartbeat loop with a large default model
can consume a weekly quota before anyone notices.

This toolkit provides a simple three-step response:

1. Diagnose recent heartbeat/token usage.
2. Disable expensive default heartbeat cadence.
3. Verify that the gateway is running with the guard active.

## Scripts

Run scripts from the project root:

```sh
cd openclaw-cost-airbag
```

### `scripts/01-diagnose-heartbeat-cost.sh`

Scans recent Codex/OpenClaw session logs and prints token-count summaries for
large runs.

```sh
./scripts/01-diagnose-heartbeat-cost.sh
```

Optional start time:

```sh
./scripts/01-diagnose-heartbeat-cost.sh "2026-06-02 21:00"
```

### `scripts/02-disable-heartbeat-cost-loop.sh`

Backs up `~/.openclaw/openclaw.json`, sets a conservative
`agents.defaults.heartbeat` block, validates the config, and reminds you to
restart the gateway.

```sh
./scripts/02-disable-heartbeat-cost-loop.sh
```

### `scripts/03-verify-cost-airbag.sh`

Prints current heartbeat config and OpenClaw status lines relevant to heartbeat
and gateway state.

```sh
./scripts/03-verify-cost-airbag.sh
```

## Guard Policy

Recommended operating policy:

- 80% weekly usage: no autonomous background research.
- 90% weekly usage: no subagents, no broad log scans, no large file reads.
- 95% weekly usage: only short answers and emergency config fixes.

## Quick Recovery

When you suspect a runaway heartbeat loop:

```sh
./scripts/01-diagnose-heartbeat-cost.sh "yesterday 21:00"
./scripts/02-disable-heartbeat-cost-loop.sh
openclaw gateway restart
./scripts/03-verify-cost-airbag.sh
```

## Notes

These scripts do not delete sessions or change model credentials. They only
patch heartbeat defaults and inspect local logs/status.

## Status

This is an early field-tested toolkit. Review paths and config output before
using it in production or on shared systems.
