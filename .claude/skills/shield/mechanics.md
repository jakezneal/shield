# Shield in Claude Code

How to carry out `.agents/dispatcher.md` with Claude Code's tools. Every shield skill uses this file in Claude Code.

| The procedure says | In Claude Code |
|---|---|
| Dispatch a role | Use the Agent tool with `subagent_type` set to `shield-<role>`: `shield-architect`, `shield-designer`, `shield-developer`, `shield-reviewer`, `shield-tester`, `shield-product-owner` or `shield-product-manager`. The prompt is the dispatch brief described in `.agents/handoffs.md`. |
| Use the model table | Pass `model` with the role's **Claude Code model** from `.agents/models.md`, and `effort` with its **Claude Code effort** unless that is `-`. If either parameter isn't accepted, dispatch without it; the agent file's values apply. |
| Wait for the report | Dispatch one role at a time and wait for its report before dispatching the next. Never run roles in parallel. If the agent runs in the background, wait for its completion notification. |
| Ask the user | Use AskUserQuestion: one decision per question, the recommended option first with "(Recommended)" in its label. Roles cannot ask the user themselves. |
| Return answers to the same role | Use SendMessage to the agent that asked, so it keeps what it has already investigated. If that isn't possible, dispatch a fresh agent; it will read the answers under `## Decisions` in `brief.md`. |
| Dispatch a Reviewer, Tester or Product Owner for acceptance | Always a fresh Agent call. Never use SendMessage to turn the Developer, or an earlier Reviewer, Tester or Product Owner, into the next one. |
| Save a report | Use the Write tool to save the role's final message to the run folder exactly as returned. |
| Read or update Jira | Use the Atlassian MCP server's tools if they are loaded (they may be deferred: search for them first), otherwise `acli` through Bash. To connect: `claude mcp add --transport http atlassian https://mcp.atlassian.com/v2/mcp`, then `/mcp` to sign in. |
| Apply `.skills/tools.md` | Roles only get the MCP tools the table lists. Tell the user to rerun shield's `install.sh --update` (with `--project` set to this project) to apply it to `.claude/agents/`, then start a new session. If a plan assigns a role a tool its agent's `tools:` line lacks, say so before dispatching. |
| Show progress | If you have a task-list tool, list the phases and keep it up to date. |

If the Agent tool says a `shield-*` agent type doesn't exist, the Claude Code adapter isn't loaded. Tell the user to check `.claude/agents/` and restart Claude Code. Never fall back to doing the role yourself.

Record the model each agent actually ran on if Claude Code reports it; otherwise write `Unknown` beside the configured model.
