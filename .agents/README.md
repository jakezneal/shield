# S.H.I.E.L.D

**Software Heuristic Intelligence & Engineering Logistics Dispatcher**: a team of AI agents that plans, designs, builds, reviews and tests changes in this project.

## Using it

### Claude Code

| Command | What it does |
|---|---|
| `/shield <request>` | Full run: plan, your approval, design if needed, develop, review, test |
| `/shield-plan <request>` | Plan only; stops once the plan is ready |
| `/shield-review [what the changes do]` | Review and test your own uncommitted changes |
| `/shield-init` | Draft `.memory/` from the codebase; run once in an existing project |

To pick up a stopped or plan-only run, use `/shield continue <run folder>`.

### Other tools

Ask the assistant to "use shield to …". Tools that read `AGENTS.md` (such as Codex, Copilot and Cursor) will find `.agents/dispatcher.md` from there. If your tool can't run agents in separate contexts, shield will ask you to open a fresh session for review and testing.

## The team

| Role | Job | Edits code? |
|---|---|---|
| Dispatcher | The main session. Coordinates the run and is the only one who talks to you | No |
| Architect | Investigates the codebase, asks blocking questions, writes the plan | No |
| Designer | Writes a design brief for UI work (only when needed) | No |
| Developer | Implements the plan, test-first for behaviour changes | Yes |
| Reviewer | Checks the change against the plan, then for quality | No |
| Tester | Verifies the change with fresh test runs | No |

## How a run works

```
request
  -> Architect plans (questions come to you via the Dispatcher)
  -> you approve the plan                      <- the only routine stop
  -> Designer briefs (UI work only)
  -> Developer builds
  -> Reviewer reviews --needs changes--+
  -> Tester verifies  --fails----------+-> Developer fixes (at most 2 rounds)
  -> summary
```

Shield also stops if a role is blocked, if a decision only you can make comes up, or if problems remain after 2 fix rounds.

## What shield will and won't do

- It works on a branch (`shield/<slug>` if you start on the default branch) and **leaves every change uncommitted** for you to review and commit. It never commits, pushes or opens pull requests.
- It writes each run's plan and reports to `.shield/runs/<date>-<slug>/`, which is gitignored.
- It adds durable knowledge to `.memory/`, which is committed. Review those changes like code.
- It never stores secrets, credentials or personal data.

## Files

| Path | Purpose | Updated by `install.sh --update`? |
|---|---|---|
| `.agents/*.md` | Role definitions and the Dispatcher procedure (work in any tool) | Yes, unless you've edited them |
| `.skills/principles.md`, `registry.md` | Shared engineering practices and skill routing | Yes, unless you've edited them |
| `.skills/local.md` | This project's skills and guidance | Never |
| `.memory/*.md` | Verified project knowledge | Never (except `README.md`) |
| `.claude/agents/shield-*.md` | Claude Code agent settings: model and tools | Yes, unless you've edited them |
| `.claude/skills/shield*/` | Claude Code slash commands | Yes, unless you've edited them |
| `.agents/shield.manifest` | Installed version and file checksums | Yes |

## Customising

- **Change how a role works**: edit `.agents/<role>.md`. This applies in every tool.
- **Change a role's model or tools in Claude Code**: edit `.claude/agents/shield-<role>.md`.
- **Point roles at project skills or guidance**: add them to `.skills/local.md`.
- **Set writing conventions** (language, commit message style): `.memory/project.md`.

When you update shield, files you've edited are kept, and the new version is written next to them as `<file>.shield-new` for you to merge.
