# TODO: Publish OpenClaw Cost Airbag

## Before Publishing

- Review README wording and decide whether to publish in German, English, or both.
- Run `bash -n scripts/*.sh`.
- Run `./scripts/03-verify-cost-airbag.sh` locally.
- Check that no secrets are present with `rg -n "sk-|token|refresh|botToken|Bearer|password|secret" .`.
- Decide repository name, recommended: `openclaw-cost-airbag`.
- Add screenshots or terminal output only after redacting paths, account names, tokens, and emails.

## GitHub Release Steps

- Create a new public GitHub repository named `openclaw-cost-airbag`.
- Add this folder as the initial project contents.
- Commit with a clear message, for example: `Initial OpenClaw cost airbag toolkit`.
- Push to GitHub.
- Add a short repository description: `Diagnose and stop runaway OpenClaw heartbeat token usage`.
- Add topics: `openclaw`, `agents`, `cost-control`, `heartbeat`, `llmops`, `automation`.

## Announcement Text

Short version:

> I published a small OpenClaw Cost Airbag toolkit after a real runaway heartbeat incident consumed a large part of a weekly model limit. It helps diagnose high-frequency heartbeat token usage, disable the loop safely, and verify the gateway state.

German version:

> Ich habe ein kleines OpenClaw Cost-Airbag-Toolkit veröffentlicht, nachdem ein echter Heartbeat-Loop einen großen Teil des Wochenlimits verbraucht hat. Es hilft dabei, solche Läufe zu diagnostizieren, die Heartbeat-Schleife sicher abzuschalten und den Gateway-Status zu prüfen.

## Where To Share

- GitHub repository README
- OpenClaw community channels, if appropriate
- LinkedIn post with a short incident summary and lessons learned
- Personal notes/blog post for AI-agent cost-control practices

## Follow-Up Improvements

- Add macOS/Linux restart detection.
- Add optional `--apply` confirmation mode.
- Add JSON output for automation.
- Add rate-limit threshold warnings from recent session logs.
- Add tests using small sample JSONL fixtures.
