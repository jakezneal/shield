# Role Tools

Project tools each shield role may use on top of its standard ones, such as a project MCP server's tools. The Architect assigns them in each plan's `## Skills` section, like skills. `/shield-init` can fill this in from the project's MCP configuration.

Shield never overwrites this file.

## Rules

- Prefer read-only tools: docs, previews, story and test runners. Never give a role a tool that writes to an outside system (tickets, chat, deployments); those stay with the Dispatcher, as `.agents/tickets.md` describes.
- Write exact tool names (`mcp__storybook__docs-list`) or a whole server (`mcp__storybook__*`), separated by commas. `-` means none.
- In Claude Code, roles only get MCP tools listed here. After editing this table, rerun shield's `install.sh --update` to apply it to `.claude/agents/`. Roles never get `Agent`, and only the Developer gets `Edit`, `Write` or `NotebookEdit`.

## Tools

| Role | Extra tools |
|---|---|
| Architect | - |
| Designer | - |
| Developer | - |
| Reviewer | - |
| Tester | - |
| Product Owner | - |
| Product Manager | - |
