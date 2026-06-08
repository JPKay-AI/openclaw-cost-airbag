# TODO: Publish OpenClaw Cost Airbag

## v0.2 Publishing

- Run `bash -n scripts/*.sh`.
- Run `./scripts/01-diagnose-heartbeat-cost.sh "yesterday 21:00"` locally.
- Run `./scripts/03-verify-cost-airbag.sh` locally.
- Check that no secrets are present with `rg -n "sk-|token|refresh|botToken|Bearer|password|secret" .`.
- Commit v0.2 changes.
- Push `main`.
- Create/push tag `v0.2`.
- Add topics: `openclaw`, `agents`, `cost-control`, `heartbeat`, `llmops`, `automation`.

## Announcement Text

Short version:

> I published a small OpenClaw Cost Airbag toolkit after a real runaway heartbeat incident consumed a large part of a weekly model limit. It helps diagnose high-frequency heartbeat token usage, disable the loop safely, and verify the gateway state.

German version:

> Ich habe ein kleines OpenClaw Cost-Airbag-Toolkit veröffentlicht, nachdem ein echter Heartbeat-Loop einen großen Teil des Wochenlimits verbraucht hat. Es hilft dabei, solche Läufe zu diagnostizieren, die Heartbeat-Schleife sicher abzuschalten und den Gateway-Status zu prüfen.

v0.2 add-on:

> v0.2 scans OpenClaw agent JSONL logs more broadly instead of only Codex session paths. The heartbeat guard itself is provider-independent at the OpenClaw config level.

## Where To Share

- GitHub repository README
- OpenClaw community channels, if appropriate
- LinkedIn post with a short incident summary and lessons learned
- Personal notes/blog post for AI-agent cost-control practices

## Follow-Up Improvements

- Add fixture tests for `04-diagnose-background-runaways.sh` using sample plist
  and log files.
- Add explicit Claude/Gemini fixture coverage once sample logs are available.
- Add macOS/Linux restart detection.
- Add optional `--apply` confirmation mode.
- Add JSON output for automation.
- Add rate-limit threshold warnings from recent session logs.
- Add tests using small sample JSONL fixtures.
