# Shield in Codex

How to carry out `.agents/dispatcher.md` with Codex's tools. Every shield skill uses this file in Codex. Shield's agents are in `.codex/agents/`, which Codex loads only in trusted projects.

| The procedure says | In Codex |
|---|---|
| Dispatch a role | Call `spawn_agent` with `agent_type` set to `shield-<role>` (`shield-architect`, `shield-designer`, `shield-developer`, `shield-reviewer`, `shield-tester`, `shield-product-owner` or `shield-product-manager`) and the dispatch brief from `.agents/handoffs.md` as the message. |
| Fresh context | **Always** spawn with `fork_turns: "none"` (older builds: leave `fork_context` unset or false). Codex otherwise gives the child this whole conversation, which breaks shield's independence rule. |
| Use the model table | Pass `model` and `reasoning_effort` with the role's **Codex model** and **Codex effort** from `.agents/models.md`. If those parameters aren't offered, spawn without them; the agent file's values apply. |
| Wait for the report | Use `wait_agent`. Dispatch one role at a time and wait for its report before dispatching the next. Never run roles in parallel. |
| Ask the user | In Plan mode, use `request_user_input` with the recommended option first. Otherwise ask in chat: one decision per message, recommended option first, then end your turn and wait for the reply. Roles cannot ask the user themselves. |
| Return answers to the same role | Use `followup_task` (older builds: `send_input`) to the agent that asked. If that isn't possible, spawn a fresh agent; it will read the answers under `## Decisions` in `brief.md`. |
| Dispatch a Reviewer, Tester or Product Owner for acceptance | Always a new `spawn_agent` with `fork_turns: "none"`. Never send follow-ups to the Developer, or an earlier Reviewer, Tester or Product Owner, to make it the next one. |
| Save a report | Write the role's final message to the run folder exactly as returned, with your file-editing tool. |
| Read or update Jira | Use the Atlassian MCP server's tools if configured (`codex mcp add atlassian --url https://mcp.atlassian.com/v2/mcp`), otherwise `acli` in the shell. |
| Apply `.skills/tools.md` | Nothing to apply: shield doesn't restrict MCP tools per agent in Codex. Name each role's allowed project tools in its brief. |
| Show progress | Use `update_plan` to list the phases and keep it up to date. |

If `spawn_agent` doesn't accept a `shield-*` agent type, Codex hasn't loaded shield's agents. Tell the user to trust the project in Codex, check `.codex/agents/`, and start a new session. Never fall back to doing the role yourself.

Codex agents inherit your sandbox, so read-only roles are read-only by instruction, not enforcement. Run Codex with a sandbox and approval policy you're comfortable with for the Developer.

Record the model each agent actually ran on if Codex reports it; otherwise write `Unknown` beside the configured model.
