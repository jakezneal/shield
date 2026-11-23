# Working on shield

This repository is the source of S.H.I.E.L.D, a multi-agent workflow pack installed into other projects. It is not an application.

## Layout

- `.agents/`, `.skills/`, `.memory/`, `.claude/`, `.codex/` and `.cursor/` are exactly what `install.sh` copies into a project (adapters only for the tools chosen with `--tools`).
- `.memory/*.md`, `.skills/local.md` and `.skills/tools.md` are **blank templates** shipped to projects. Never add knowledge about shield itself to them, and don't run shield workflows in this repository that would write to them.
- `templates/` holds the sections `install.sh` adds to a project's `AGENTS.md`, `CLAUDE.md` and `.gitignore`.
- This `AGENTS.md` and `CLAUDE.md` are for working on shield. They are not installed.

## Rules

- **Canonical behaviour lives in `.agents/*.md` and stays tool-neutral.** Tool-specific mechanics belong in adapters: `.claude/` (Claude Code), `.codex/` (Codex), `.cursor/` (Cursor), and `.agents/skills/` (the shared Agent Skills entry points Codex and Cursor read). An adapter points at the canonical file and repeats only the must-follow rules, so the two can't drift.
- **Keep adapters in step.** Each `shield-*` skill has the same `SKILL.md` in `.claude/skills/` and `.agents/skills/`, apart from `argument-hint`. Each role's agent body is the same in `.claude/agents/`, `.codex/agents/` (`developer_instructions`) and `.cursor/agents/`, and its models match `.agents/models.md`. The tests check all of this.
- **Keep role files lean.** Every line is loaded into an agent's context on every run.
- **Any change to an installed file**: bump `VERSION` (semantic versioning) and add a `CHANGELOG.md` entry.
- **Installer changes** must stay idempotent, never overwrite a user's file without `--force`, preserve local edits, and keep working in plain POSIX `sh`.
- **New installed files** are picked up automatically if they live under `.agents/` (Markdown), `.claude/agents/shield-*.md`, `.claude/skills/shield*/`, `.codex/agents/shield-*.toml`, `.cursor/agents/shield-*.md` or `.agents/skills/shield*/`. Anything else needs adding to `list_managed` or `SEED_FILES` in `install.sh`.
- **Verify before claiming success**: run `sh tests/test-install.sh` and `TEST_SHELL=dash sh tests/test-install.sh`.
- **Writing style**: British English, no em dashes.
