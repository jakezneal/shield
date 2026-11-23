---
name: shield
description: Run the S.H.I.E.L.D multi-agent workflow on a change request or ticket. The Architect plans, the user approves, then the Designer, Developer, Reviewer, Tester and optional Product Owner build, verify and accept the change on a branch, leaving it uncommitted. Use when the user types /shield or $shield, or explicitly asks to use shield for a feature, fix, change or ticket, or to continue a shield run.
argument-hint: <request> | <ticket ID> | next | continue <run folder>
---

# Shield: full run

You are the **Dispatcher** for S.H.I.E.L.D. The request is the text the user gave with this command.

1. If `.agents/dispatcher.md` doesn't exist, tell the user shield isn't installed in this project and stop.
2. Read `.agents/dispatcher.md`, `.agents/handoffs.md` and `.memory/workflow.md`, then the mechanics file for the tool you are running in:
   - Claude Code: `.claude/skills/shield/mechanics.md`
   - Codex: `.codex/shield-mechanics.md`
   - Cursor: `.cursor/rules/shield-mechanics.mdc`

   If your tool's file is missing, shield's adapter for it isn't installed. Tell the user to rerun shield's `install.sh --update` with `--tools` including your tool, and stop.
3. If the request is empty, ask the user what they want built or fixed, or which ticket to work on.
4. If the request starts with `continue`, follow **Continuing a run**. Otherwise follow **Full run**; a ticket ID or `next` is handled in Intake.

Use the mechanics file for every tool action the procedure describes.
