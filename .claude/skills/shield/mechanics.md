# Shield in Claude Code

How to carry out `.agents/dispatcher.md` with Claude Code's tools. Every shield skill uses this file.

| The procedure says | In Claude Code |
|---|---|
| Dispatch a role | Use the Agent tool with `subagent_type` set to `shield-architect`, `shield-designer`, `shield-developer`, `shield-reviewer` or `shield-tester`. The prompt is the dispatch brief described in `.agents/handoffs.md`. |
| Wait for the report | Dispatch one role at a time and wait for its report before dispatching the next. Never run roles in parallel. If the agent runs in the background, wait for its completion notification. |
| Ask the user | Use AskUserQuestion: one decision per question, the role's recommended option first with "(Recommended)" in its label. Roles cannot ask the user themselves. |
| Return answers to the same role | Use SendMessage to the agent that asked, so it keeps what it has already investigated. If that isn't possible, dispatch a fresh agent; it will read the answers under `## Decisions` in `brief.md`. |
| Dispatch a Reviewer or Tester | Always a fresh Agent call. Never use SendMessage to turn the Developer, or an earlier Reviewer or Tester, into the next reviewer or tester. |
| Save a report | Use the Write tool to save the role's final message to the run folder exactly as returned. |
| Show progress | If you have a task-list tool, list the phases and keep it up to date. |

If the Agent tool says a `shield-*` agent type doesn't exist, the Claude Code adapter isn't loaded. Tell the user to check `.claude/agents/` and restart Claude Code. Never fall back to doing the role yourself.
