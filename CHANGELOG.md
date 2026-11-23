# Changelog

## 0.1.0 (16/11/2026)

First release.

- Five roles (Architect, Designer, Developer, Reviewer, Tester) and the Dispatcher procedure, written to work in any tool.
- Handoff contract: gitignored run folder, report format, status words, findings and a two-round fix loop.
- One routine approval stop, after the plan. Changes are left uncommitted on a branch.
- Shared engineering principles, skill routing, and project memory templates.
- Claude Code adapter: `shield-*` subagents and the `/shield`, `/shield-plan`, `/shield-review` and `/shield-init` skills.
- `install.sh` with install, `--update`, `--uninstall`, `--dry-run` and `--force`, tracking installed files by checksum so local edits are preserved.
