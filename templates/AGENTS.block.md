<!-- shield:start: managed by shield's install.sh. Edits between these markers are replaced on update. -->
## S.H.I.E.L.D agent team

This project uses shield: a team of agents (Architect, Designer, Developer, Reviewer, Tester) coordinated by the main assistant session acting as Dispatcher. Guide: `.agents/README.md`.

- When the user runs `/shield` or asks to use shield, follow `.agents/dispatcher.md`. Don't start a shield run unprompted; for a substantial change you may suggest one.
- Project memory lives in `.memory/`. Read `project.md` for orientation, `commands.md` before running build or test commands, `decisions.md` before architectural changes, and `pitfalls.md` before debugging. Follow `.memory/README.md` when adding to it, and never store secrets there.
- Shield run reports live in `.shield/runs/`, which is gitignored.
- Work is never reviewed or tested in the same context that produced it.
<!-- shield:end -->
