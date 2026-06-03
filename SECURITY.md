# Security

Do not publish real OpenClaw config files, session logs, auth profiles, tokens,
refresh tokens, or screenshots containing account identifiers.

Before opening an issue or pull request with diagnostics, redact:

- API keys
- OAuth tokens
- bot tokens
- email addresses
- phone numbers
- local filesystem paths that reveal private project names
- full session transcripts

These scripts are designed to inspect local state and patch heartbeat defaults.
Review command output before sharing it publicly.
