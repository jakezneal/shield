# Agents of S.H.I.E.L.D

**Software Heuristic Intelligence & Engineering Logistics Dispatcher**

A reusable multi-agent workflow you install into new or existing projects. A team of five specialist agents (Architect, Designer, Developer, Reviewer and Tester) plans, designs, builds, reviews and tests changes, coordinated by your main assistant session acting as the **Dispatcher**.

The role definitions are plain Markdown that any AI coding tool can read. v1 ships an adapter for **Claude Code**: five subagents and four slash commands.

## How a run works

```
/shield add CSV export to the reports page
  |
  |  Architect   investigates the code, asks you blocking questions, writes a plan
  |  >> you approve the plan                                <- the only routine stop
  |  Designer    writes a design brief (UI work only)
  |  Developer   builds it on a branch, test-first
  |  Reviewer    checks it against the plan, then for quality  --+
  |  Tester      verifies it with fresh test runs               --+-> fixes, at most 2 rounds
  v
summary: what changed, evidence, open issues, suggested commit message
```

- Every role runs in its own fresh context. The Developer never reviews or tests its own work.
- Changes are left **uncommitted** on a branch for you to review and commit. Shield never commits, pushes or opens pull requests.
- Plans and reports are saved to `.shield/runs/<date>-<slug>/` (gitignored), so you can see exactly what each role did.
- Durable knowledge (working commands, decisions, pitfalls) builds up in `.memory/`, which is committed and shared with your team.

## Commands (Claude Code)

| Command | What it does |
|---|---|
| `/shield <request>` | Full run |
| `/shield continue <run folder>` | Pick up a stopped or plan-only run |
| `/shield-plan <request>` | Plan only |
| `/shield-review [what the changes do]` | Review and test your own uncommitted changes |
| `/shield-init` | Draft `.memory/` from an existing codebase |

In other tools, ask the assistant to "use shield to …". It finds `.agents/dispatcher.md` through `AGENTS.md`.

## Install

Clone this repository, then run the installer against your project:

```bash
git clone <shield repository URL> ~/Code/shield
```

```bash
~/Code/shield/install.sh --project /path/to/your/project
```

Or from inside the project:

```bash
~/Code/shield/install.sh --here
```

Preview any command first with `--dry-run`. Then commit the new files and start a new Claude Code session. In an existing project, run `/shield-init` to fill in `.memory/`.

### What it adds to a project

```
AGENTS.md          shield section between markers (your content is left alone)
CLAUDE.md          "@AGENTS.md" import between markers, unless it already imports AGENTS.md
.gitignore         ".shield/" between markers
.agents/           role definitions, Dispatcher procedure, handoff contract, manifest
.skills/           shared principles, skill routing, and local.md for project-specific skills
.memory/           project, commands, decisions, pitfalls (created if missing, never overwritten)
.claude/agents/    shield-architect, -designer, -developer, -reviewer, -tester
.claude/skills/    shield, shield-plan, shield-review, shield-init
```

### Update

```bash
~/Code/shield/install.sh --project /path/to/your/project --update
```

Files you haven't edited are updated. Files you have edited are kept, and the new version is written beside them as `<file>.shield-new` for you to merge. `.memory/` and `.skills/local.md` are never touched. Add `--force` to replace edited files instead; your versions are backed up under `.shield/backups/`.

### Uninstall

```bash
~/Code/shield/install.sh --project /path/to/your/project --uninstall
```

Removes shield's files and marked sections. Keeps `.memory/`, `.skills/local.md`, files you've edited, and `.shield/` run history.

### Requirements

- macOS or Linux with a POSIX shell, `sha256sum` or `shasum`, and the usual command-line tools. Windows should work through WSL or Git Bash, but is untested.
- Claude Code for the bundled adapter.

## Default models (Claude Code)

| Role | Model | Tools |
|---|---|---|
| Architect | `opus`, high effort | Read-only, plus web research |
| Designer | `sonnet` | Everything except editing files, so design tools such as Figma are available |
| Developer | `sonnet` | Read, edit, shell, web |
| Reviewer | `opus`, high effort | Read-only, plus shell for `git diff` and narrow reproductions |
| Tester | `sonnet` | Everything except editing files, so browser and test tools are available |

Change these in `.claude/agents/shield-<role>.md` in your project.

Note: the Reviewer and Tester need shell access for git and tests. Removing their edit tools stops them editing files directly, but a shell command could still change a file; only their instructions forbid it.

## Repository layout

| Path | Purpose |
|---|---|
| `.agents/`, `.skills/`, `.memory/`, `.claude/` | Exactly what gets installed. `.memory/` and `.skills/local.md` are blank templates |
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

Shield takes inspiration from [dsmailes/dev-team](https://github.com/dsmailes/dev-team) (MIT): the role split, the Architect's investigate-then-ask protocol, spec-then-quality review, fresh verification evidence, the limited fix loop, and `.memory/`. It deliberately leaves out tickets, the ticket dashboard, operating modes and runner evidence, and Codex-specific model routing, in favour of a lighter run folder and a single plan-approval stop.

Possible next steps:

- Adapters for other tools (for example GitHub Copilot custom agents or Codex)
- Hooks that save role reports automatically
- Optional worktree isolation for parallel runs

## Licence

To be decided.
