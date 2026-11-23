# S.H.I.E.L.D

**Software Heuristic Intelligence & Engineering Logistics Dispatcher**: a team of AI agents that plans, designs, builds, reviews and tests changes in this project.

## Using it

| What | Claude Code and Cursor | Codex |
|---|---|---|
| Full run on a request | `/shield <request>` | `$shield <request>` |
| Full run on a ticket | `/shield <ticket ID>` or `/shield next` | `$shield <ticket ID>` or `$shield next` |
| Continue a stopped or plan-only run | `/shield continue <run folder>` | `$shield continue <run folder>` |
| Plan only | `/shield-plan <request or ticket ID>` | `$shield-plan ...` |
| Review and test your own uncommitted changes | `/shield-review [what they do]` | `$shield-review ...` |
| Show, draft, refine or prioritise tickets | `/shield-ticket [idea, refine <ID>, prioritise, done <ID>]` | `$shield-ticket ...` |
| Set up tickets, product roles and memory | `/shield-init` | `$shield-init` |

In any other tool that reads `AGENTS.md`, ask the assistant to "use shield to …". If it can't run agents in separate contexts, shield will ask you to open a fresh session for review and testing.

**Codex**: trust the project (Codex only loads `.codex/` in trusted projects) so the shield agents load.

## The team

| Role | Job | Edits code? |
|---|---|---|
| Dispatcher | The main session. Coordinates the run and is the only one who talks to you | No |
| Product Manager | Optional. Shapes larger ideas into a brief and ordered tickets; proposes priorities | No |
| Product Owner | Optional. Writes tickets, answers product questions, accepts finished work | No |
| Architect | Investigates the codebase, asks blocking questions, writes the plan | No |
| Designer | Writes a design brief for UI work (only when needed) | No |
| Developer | Implements the plan, test-first for behaviour changes | Yes |
| Reviewer | Checks the change against the plan, then for quality | No |
| Tester | Verifies the change with fresh test runs | No |

Models for each role, in each tool, are set in `.agents/models.md`.

## How a run works

```
request or ticket
  -> Architect plans (product questions go to the Product Owner agent if set, otherwise to you)
  -> you approve the plan                      <- the only routine stop
  -> Designer briefs (UI work only)
  -> Developer builds
  -> Reviewer reviews --needs changes--+
  -> Tester verifies  --fails----------+-> Developer fixes (at most 2 rounds)
  -> Product Owner accepts (agent only) --+
  -> summary, ticket moves to Review
```

Shield also stops if a role is blocked, if a decision only you can make comes up, or if problems remain after 2 fix rounds.

## How you work with it

Set these in `.memory/workflow.md`, or run `/shield-init`.

| Situation | Settings | What changes |
|---|---|---|
| Plain requests, no product roles | Defaults | Nothing: you answer every question |
| Tickets written ahead of time | `Source: local` | Tickets live in `.tickets/`; the order of Ready is the priority; `next` takes the top one |
| A team using Jira | `Source: jira` | Shield reads tickets from Jira and, if you allow it, updates them after asking you each time |
| A team with a PO or PM | `Product Owner` / `Product Manager: human` | Product questions are labelled for them; the summary includes notes for them |
| Working alone, wanting both | `Product Owner` / `Product Manager: agent` | Shield's agents shape ideas into tickets, answer product questions, and accept finished work |

## What shield will and won't do

- It works on a branch (`shield/<slug>`, or `shield/<ticket ID>-<slug>`, if you start on the default branch) and **leaves every change uncommitted** for you to review and commit. It never commits, pushes or opens pull requests.
- It writes each run's plan and reports to `.shield/runs/<date>-<slug>/`, which is gitignored.
- It updates `.tickets/` and adds durable knowledge to `.memory/`, both committed. Review those changes like code.
- It writes to Jira only after showing you the exact change and getting your yes, and never if you set `Jira updates: off`. It never asks for API tokens.
- It never stores secrets, credentials or personal data.

## Files

| Path | Purpose | Updated by `install.sh --update`? |
|---|---|---|
| `.agents/*.md`, `.agents/templates/` | Roles, Dispatcher procedure, handoffs, tickets, models, templates | Yes, unless you've edited them |
| `.agents/skills/shield*/` | Commands for Codex and Cursor | Yes, unless you've edited them |
| `.skills/principles.md`, `registry.md` | Shared engineering practices and skill routing | Yes, unless you've edited them |
| `.skills/local.md` | This project's skills and guidance | Never |
| `.skills/tools.md` | Project tools (such as MCP servers) each role may use | Never |
| `.memory/*.md` | Project knowledge, product context and workflow settings | Never (except `README.md`) |
| `.tickets/` | Local tickets, if you use them | Never |
| `.claude/agents/`, `.claude/skills/shield*/` | Claude Code agents and commands | Yes, unless you've edited them |
| `.codex/agents/`, `.codex/shield-mechanics.md` | Codex agents and how to run shield in Codex | Yes, unless you've edited them |
| `.cursor/agents/`, `.cursor/rules/shield-mechanics.mdc` | Cursor agents and how to run shield in Cursor | Yes, unless you've edited them |
| `.agents/shield.manifest` | Installed version, tools and file checksums | Yes |

## Customising

- **Change how a role works**: edit `.agents/<role>.md`. This applies in every tool.
- **Change a role's model**: edit `.agents/models.md`.
- **Give roles project MCP tools**: list them in `.skills/tools.md`, then rerun `install.sh --update` to apply them to the Claude Code agents.
- **Change a role's other tools or permissions**: edit that tool's agent file.
- **Point roles at project skills or guidance**: add them to `.skills/local.md`.
- **Set writing conventions** (language, commit message style): `.memory/project.md`.

When you update shield, files you've edited are kept, and the new version is written next to them as `<file>.shield-new` for you to merge.
