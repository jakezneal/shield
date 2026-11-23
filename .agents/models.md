# Models

Which model each role runs on, in each tool. This table is the single place to change a role's model.

| Role | Claude Code model | Claude Code effort | Codex model | Codex effort | Cursor model |
|---|---|---|---|---|---|
| Architect | `opus` | `high` | `gpt-6.2-astra` | `high` | `claude-opus-5-5[effort=high]` |
| Designer | `sonnet` | `-` | `gpt-6.2-sol` | `medium` | `claude-sonnet-5-5` |
| Developer | `sonnet` | `-` | `gpt-6.2-sol` | `medium` | `claude-sonnet-5-5` |
| Reviewer | `opus` | `high` | `gpt-6.2-astra` | `high` | `claude-opus-5-5[effort=high]` |
| Tester | `sonnet` | `-` | `gpt-6.2-sol` | `medium` | `claude-sonnet-5-5` |
| Product Owner | `sonnet` | `-` | `gpt-6.2-sol` | `medium` | `claude-sonnet-5-5` |
| Product Manager | `opus` | `-` | `gpt-6.2-astra` | `medium` | `claude-opus-5-5` |

`-` means the tool's default. The Dispatcher runs on whatever model your session uses.

## How the table is used

- The Dispatcher reads the row for the role and the columns for the tool it is running in, and passes that model and effort on every dispatch. Your tool's mechanics file says how.
- Each tool's agent files (`.claude/agents/`, `.codex/agents/`, `.cursor/agents/`) carry the same values as a fallback, for when a tool can't take a model per dispatch.
- If a model isn't available, the dispatch falls back to the agent file's value or the session's model. The Dispatcher records the configured model and the actual one (or `Unknown`) in `summary.md`.

## Changing a model

1. Edit the table. The change applies from the next dispatch.
2. If your tool can't choose a model per dispatch, also change that role's agent file. `install.sh --update` will then keep your edited file and put shield's new version beside it.

Check which models you can use: `claude` `/model`, `codex` `/model`, or `agent models` in Cursor's CLI. Model names and effort levels change often, and admins can restrict them.

## Choosing models

- **Architect and Reviewer**: the most capable reasoning model. Planning and review errors are the most expensive to fix later.
- **Developer, Designer, Tester, Product Owner**: a balanced coding model.
- **Product Manager**: a capable reasoning model; it runs rarely.
- Where a tool offers more than one provider, a Reviewer from a different model family to the Developer gives a more independent review.
