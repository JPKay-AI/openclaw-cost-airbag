# OpenClaw Cost Airbag

Small operational scripts for diagnosing and stopping accidental high-frequency
OpenClaw heartbeat/model runs.

Version: v0.3

## Why

Agent runtimes can become expensive when background wakeups repeatedly start
large-context model turns. A 30 minute heartbeat loop with a large default model
can consume a weekly quota before anyone notices.

This toolkit provides a simple four-step response:

1. Diagnose recent heartbeat/token usage.
2. Disable expensive default heartbeat cadence.
3. Verify that the gateway is running with the guard active.
4. Check for related local background runaways such as short-interval
   LaunchAgents, growing OpenClaw logs, hook relays, and stale memory indexes.

## Scripts

Run scripts from the project root:

```sh
cd openclaw-cost-airbag
```

### `scripts/01-diagnose-heartbeat-cost.sh`

Scans recent OpenClaw agent JSONL logs and prints token-count summaries for
large runs. It is provider-neutral at the log-scanning layer: Codex/OpenAI,
Claude, Gemini, or other providers are included when OpenClaw writes compatible
`token_count` events.

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

Prints current heartbeat config, OpenClaw status lines relevant to heartbeat
and gateway state, and a compact background runaway check.

```sh
./scripts/03-verify-cost-airbag.sh
```

### `scripts/04-diagnose-background-runaways.sh`

Read-only local guard for non-heartbeat loops that can still make an agent
runtime expensive or sluggish. It checks OpenClaw-related LaunchAgents, short
sample log growth, suspicious high-CPU hook/node/device processes, and memory
index readiness.

```sh
./scripts/04-diagnose-background-runaways.sh
```

Shorter or longer log sample:

```sh
./scripts/04-diagnose-background-runaways.sh --sample-seconds 10
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
./scripts/04-diagnose-background-runaways.sh
```

## Notes

These scripts do not delete sessions or change model credentials. They only
patch heartbeat defaults and inspect local logs/status.

The heartbeat shutdown script is OpenClaw-level and provider-independent. The
diagnosis script depends on OpenClaw session logs containing `token_count`
events; provider-specific logs without those events may not be summarized.

## Status

Field-tested with OpenClaw + Codex/OpenAI on macOS. v0.2 broadens log scanning
to OpenClaw agent JSONL logs across providers, while keeping the heartbeat guard
at the OpenClaw config level. v0.3 adds local runaway checks for LaunchAgents,
logs, hook/node/device processes, and memory index health.
