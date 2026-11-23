# Changelog

## 0.3.0 (23/11/2026)

- **Project tools per role.** New `.skills/tools.md` lists the extra tools each role may use, such as a project MCP server's (`mcp__storybook__docs-list`, or `mcp__storybook__*` for a whole server). `install.sh` adds them to each Claude Code agent's `tools:` line and records the merged file, so a table change isn't treated as a local edit. Roles never get `Agent`, and only the Developer gets edit tools.
- **Allowlists for every role.** The Designer and Tester now use `tools:` instead of `disallowedTools:`, so no role inherits an outside system's write tools (such as Jira) by accident. Give them design or browser MCP tools through `.skills/tools.md`.
- **`/shield-init`** reads the project's MCP servers and asks which roles may use which tools, suggesting read-only ones and never offering write tools to roles.
- **Project servers.** A new rule in `handoffs.md`: a role that needs a project server (such as Storybook) starts it in the background, checks it serves this checkout, stops it before reporting, and reports anything that needed it as not run if it won't start.
- Skill routing counts project MCP tools as skills, and the Tester names the exact story or page and its URL in manual checks.

## 0.2.0 (23/11/2026)

- **Codex and Cursor adapters.** Shield agents in `.codex/agents/` and `.cursor/agents/`, a mechanics file for each tool, and tool-neutral commands in `.agents/skills/` (Codex and Cursor) matching `.claude/skills/`. Codex runs spawn every role with a fresh context. Cursor's own agents take precedence over the Claude Code copies it also loads.
- **Model table.** `.agents/models.md` sets each role's model and effort for Claude Code, Codex and Cursor. The Dispatcher passes them on every dispatch and records the configured and actual model.
- **Tickets.** Local tickets in `.tickets/` (the order of Ready is the priority) or Jira, through the Atlassian MCP server or `acli`. `/shield <ticket ID>`, `/shield next`, and a new `/shield-ticket` command to show, draft, refine, prioritise and close tickets. Jira writes need the user's yes each time, or can be turned off.
- **Product roles.** Optional Product Owner and Product Manager, each `none`, `human` or `agent`. The Product Owner agent drafts tickets, answers product questions and accepts finished work; the Product Manager agent breaks larger ideas into a brief and ordered tickets. Human roles get labelled questions and notes in the summary.
- **Settings.** New `.memory/workflow.md` (ticket source and product roles) and `.memory/product.md` (product context). `/shield-init` now sets these up.
- **Installer.** `--tools` chooses which adapters to install, remembered in the manifest. Defaults to all three.

## 0.1.0 (16/11/2026)

First release.

- Five roles (Architect, Designer, Developer, Reviewer, Tester) and the Dispatcher procedure, written to work in any tool.
- Handoff contract: gitignored run folder, report format, status words, findings and a two-round fix loop.
- One routine approval stop, after the plan. Changes are left uncommitted on a branch.
- Shared engineering principles, skill routing, and project memory templates.
- Claude Code adapter: `shield-*` subagents and the `/shield`, `/shield-plan`, `/shield-review` and `/shield-init` skills.
- `install.sh` with install, `--update`, `--uninstall`, `--dry-run` and `--force`, tracking installed files by checksum so local edits are preserved.
