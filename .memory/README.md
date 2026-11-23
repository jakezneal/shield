# Project Memory

Durable, verified facts about this project that agents and people should not have to rediscover. This folder is committed, so treat changes to it like code changes.

Memory is for stable project knowledge, not notes about the current task. Task notes live in the shield run folder (`.shield/runs/`).

## Files

| File | Holds | Read it |
|---|---|---|
| `project.md` | Purpose, stack, architecture, important paths, conventions | For orientation, before planning |
| `commands.md` | Setup, build, test, lint and run commands that actually work | Before running any of those |
| `decisions.md` | Durable decisions and the reasons behind them | Before proposing architectural changes |
| `pitfalls.md` | Repeated mistakes, environment traps, sharp edges | Before debugging or touching fragile areas |

## Writing rules

- Add only durable, verified knowledge. If it only matters to the current task, leave it out.
- Keep entries short. Prefer exact commands and file paths to prose.
- Date entries that may go stale (DD/MM/YYYY).
- Update or remove an entry that has become wrong rather than adding a contradicting one.
- **Never store secrets, credentials, tokens, private keys or personal data.**
- Don't paste raw logs, except a short excerpt that explains a pitfall.

During shield runs, roles propose memory updates in their reports and only the Dispatcher writes them here.
