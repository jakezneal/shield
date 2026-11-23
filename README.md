# Agents of S.H.I.E.L.D

**Software Heuristic Intelligence & Engineering Logistics Dispatcher**

A reusable multi-agent workflow you install into new or existing projects. A team of specialist agents (Architect, Designer, Developer, Reviewer and Tester, plus an optional Product Owner and Product Manager) plans, designs, builds, reviews and tests changes, coordinated by your main assistant session acting as the **Dispatcher**.

The role definitions are plain Markdown that any AI coding tool can read. Shield ships adapters for **Claude Code**, **Codex** and **Cursor**: the same agents and commands in each, with the model for every role set in one table.

## How a run works

```
/shield add CSV export to the reports page     (or /shield T-4, /shield ABC-123, /shield next)
  |
  |  Architect   investigates the code, asks you blocking questions, writes a plan
  |  >> you approve the plan                                <- the only routine stop
  |  Designer    writes a design brief (UI work only)
  |  Developer   builds it on a branch, test-first
  |  Reviewer    checks it against the plan, then for quality  --+
  |  Tester      verifies it with fresh test runs               --+-> fixes, at most 2 rounds
  |  Product Owner accepts it against the ticket (agent only) --+
  v
summary: what changed, evidence, open issues, suggested commit message
```

- Every role runs in its own fresh context. The Developer never reviews or tests its own work.
- Changes are left **uncommitted** on a branch for you to review and commit. Shield never commits, pushes or opens pull requests.
- Plans and reports are saved to `.shield/runs/<date>-<slug>/` (gitignored), so you can see exactly what each role did.
- Durable knowledge (working commands, decisions, pitfalls) builds up in `.memory/`, which is committed and shared with your team.

## Commands

Type these as shown in Claude Code and Cursor. In Codex, use `$` instead of `/` (for example `$shield next`).

| Command | What it does |
|---|---|
| `/shield <request>` | Full run on a request |
| `/shield <ticket ID>`, `/shield next` | Full run on a ticket, or on the top Ready ticket |
| `/shield continue <run folder>` | Pick up a stopped, paused or plan-only run |
| `/shield-plan <request or ticket ID>` | Plan only |
| `/shield-review [what the changes do]` | Review and test your own uncommitted changes |
| `/shield-ticket [idea, refine <ID>, prioritise, done <ID>]` | Show the board, or draft, refine, reorder or close tickets |
| `/shield-init` | Choose tickets and product roles, and draft `.memory/` from the codebase |

In other tools, ask the assistant to "use shield to …". It finds `.agents/dispatcher.md` through `AGENTS.md`.

## Ways of working

Run `/shield-init` to choose, or edit `.memory/workflow.md`.

| Situation | Settings | How you work |
|---|---|---|
| No tickets, no product roles | Defaults | `/shield <request>`; you answer every question |
| Tickets written ahead of time | `Source: local` | Write tickets in `.tickets/` (or `/shield-ticket <idea>`), order the Ready list, then `/shield next` |
| A team using Jira | `Source: jira` | `/shield ABC-123` or `/shield next` (from your ready query). Shield reads Jira through the Atlassian MCP server or `acli`, and only writes after showing you the change and getting your yes |
| A team with a Product Owner or Product Manager | `human` | Product questions are labelled for them, and the summary includes an acceptance checklist for the PO and an update for the PM |
| Working alone, wanting both | `agent` | `/shield-ticket <idea>`: the Product Manager shapes it into a brief and ordered tickets, the Product Owner refines them, answers product questions during runs, and accepts the finished work |

The Product Owner and Product Manager can each be `none`, `human` or `agent`, independently. Plan approval always stays with you.

## Install

Clone this repository, then run the installer against your project:

```bash
git clone https://github.com/jakezneal/shield ~/Code/shield
```

```bash
~/Code/shield/install.sh --project /path/to/your/project
```

Or from inside the project:

```bash
~/Code/shield/install.sh --here
```

Preview any command first with `--dry-run`. Then commit the new files and start a new session in your tool. Run `/shield-init` to choose tickets and product roles, and to fill in `.memory/`.

By default shield installs adapters for all three tools. To install only some:

```bash
~/Code/shield/install.sh --here --tools claude,cursor
```

Updates remember the choice; pass `--tools` again with `--update` to change it.

### What it adds to a project

```
AGENTS.md          shield section between markers (your content is left alone)
CLAUDE.md          "@AGENTS.md" import between markers, unless it already imports AGENTS.md (Claude Code only)
.gitignore         ".shield/" between markers
.agents/           roles, Dispatcher procedure, handoffs, tickets, model table, templates, manifest
.agents/skills/    shield commands for Codex and Cursor
.skills/           shared principles, skill routing, local.md for project-specific skills, tools.md for each role's project tools
.memory/           project, product, workflow, commands, decisions, pitfalls (created if missing, never overwritten)
.claude/           Claude Code agents (shield-*) and commands
.codex/            Codex agents (shield-*.toml) and shield-mechanics.md
.cursor/           Cursor agents (shield-*) and rules/shield-mechanics.mdc
```

`.tickets/` is created by `/shield-init` only if you choose local tickets.

### Update

```bash
~/Code/shield/install.sh --project /path/to/your/project --update
```

Files you haven't edited are updated. Files you have edited are kept, and the new version is written beside them as `<file>.shield-new` for you to merge. `.memory/`, `.skills/local.md`, `.skills/tools.md` and `.tickets/` are never touched. Each Claude Code agent gets the extra tools `.skills/tools.md` lists for its role. Add `--force` to replace edited files instead; your versions are backed up under `.shield/backups/`.

### Uninstall

```bash
~/Code/shield/install.sh --project /path/to/your/project --uninstall
```

Removes shield's files and marked sections. Keeps `.memory/`, `.skills/local.md`, `.skills/tools.md`, `.tickets/`, files you've edited, and `.shield/` run history.

### Requirements

- macOS or Linux with a POSIX shell, `sha256sum` or `shasum`, and the usual command-line tools. Windows should work through WSL or Git Bash, but is untested.
- Claude Code, Codex or Cursor, recent enough to support subagents and skills. Codex only loads `.codex/` in projects you trust.
- For Jira: the Atlassian MCP server or the Atlassian CLI (`acli`), signed in. Your Atlassian admin may need to allow the MCP server.

## Models

Every role's model, in every tool, is set in one table: `.agents/models.md` in your project. The Dispatcher passes the table's model and effort on each dispatch, and the agent files carry the same values as a fallback.

| Role | Claude Code | Codex | Cursor |
|---|---|---|---|
| Architect, Reviewer | `opus`, high effort | `gpt-6.2-astra`, high | `claude-opus-5-5[effort=high]` |
| Product Manager | `opus` | `gpt-6.2-astra`, medium | `claude-opus-5-5` |
| Designer, Developer, Tester, Product Owner | `sonnet` | `gpt-6.2-sol`, medium | `claude-sonnet-5-5` |

Model names change often. Check what your account can use (`/model` in Claude Code or Codex, `agent models` in Cursor's CLI) and edit the table.

## Tools and permissions

| Role | Claude Code | Cursor | Codex |
|---|---|---|---|
| Architect, Reviewer, Product Owner, Product Manager | Read-only tools, plus shell | `readonly: true` | By instruction only |
| Designer | Everything except editing files, so design tools such as Figma are available | `readonly: true` | By instruction only |
| Developer | Read, edit, shell, web | Full | Full |
| Tester | Everything except editing files, so browser and test tools are available | Full (it must run tests) | By instruction only |

Codex agents inherit your session's sandbox, so it can't make a role read-only. In every tool, roles that need a shell could still change a file through it; only their instructions forbid it.

## Repository layout

| Path | Purpose |
|---|---|
| `.agents/`, `.skills/`, `.memory/`, `.claude/`, `.codex/`, `.cursor/` | Exactly what gets installed. `.memory/`, `.skills/local.md` and `.skills/tools.md` are blank templates |
| `templates/` | Sections added to a project's `AGENTS.md`, `CLAUDE.md` and `.gitignore` |
| `install.sh` | Installer |
| `tests/test-install.sh` | Installer and structure tests |
| `VERSION`, `CHANGELOG.md` | Release version and history |

## Testing

```bash
sh tests/test-install.sh
```

```bash
TEST_SHELL=dash sh tests/test-install.sh
```

## Design notes

Shield takes inspiration from [dsmailes/dev-team](https://github.com/dsmailes/dev-team) (MIT): the role split, the Architect's investigate-then-ask protocol, spec-then-quality review, fresh verification evidence, the limited fix loop, `.memory/`, local tickets and a per-tool model table. It deliberately leaves out the ticket dashboard, operating modes, runner evidence and cross-provider fallback routing, in favour of a lighter run folder, a single plan-approval stop, and tickets whose state lives in one queue file.

Possible next steps:

- Other ticket sources, such as GitHub Issues or Linear
- Hooks that save role reports automatically
- Optional worktree isolation for parallel runs

## Licence

To be decided.
