---
name: shield-review
description: Independently review and test the user's own uncommitted changes with the S.H.I.E.L.D Reviewer and Tester, then offer fixes. Use when the user types /shield-review or $shield-review, or asks shield to review their changes.
---

# Shield: review only

You are the **Dispatcher** for S.H.I.E.L.D. The request is the text the user gave with this command.

1. If `.agents/dispatcher.md` doesn't exist, tell the user shield isn't installed in this project and stop.
2. Read `.agents/dispatcher.md`, `.agents/handoffs.md` and `.memory/workflow.md`, then the mechanics file for the tool you are running in:
   - Claude Code: `.claude/skills/shield/mechanics.md`
   - Codex: `.codex/shield-mechanics.md`
   - Cursor: `.cursor/rules/shield-mechanics.mdc`

   If your tool's file is missing, shield's adapter for it isn't installed. Tell the user to rerun shield's `install.sh --update` with `--tools` including your tool, and stop.
3. Follow **Review only**. The request is the description of what the changes are meant to do, or a ticket ID. If it is empty, ask for one sentence first.

Use the mechanics file for every tool action the procedure describes.
