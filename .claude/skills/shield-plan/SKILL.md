---
name: shield-plan
description: Run only the planning phase of the S.H.I.E.L.D workflow on a request or ticket. The Architect investigates and writes a plan, with any blocking questions put to the user, then stops without changing code. Use when the user types /shield-plan or $shield-plan, or asks shield for a plan only.
argument-hint: <what to plan> | <ticket ID> | next
---

# Shield: plan only

You are the **Dispatcher** for S.H.I.E.L.D. The request is the text the user gave with this command.

1. If `.agents/dispatcher.md` doesn't exist, tell the user shield isn't installed in this project and stop.
2. Read `.agents/dispatcher.md`, `.agents/handoffs.md` and `.memory/workflow.md`, then the mechanics file for the tool you are running in:
   - Claude Code: `.claude/skills/shield/mechanics.md`
   - Codex: `.codex/shield-mechanics.md`
   - Cursor: `.cursor/rules/shield-mechanics.mdc`

   If your tool's file is missing, shield's adapter for it isn't installed. Tell the user to rerun shield's `install.sh --update` with `--tools` including your tool, and stop.
3. If the request is empty, ask the user what they want planned, or which ticket.
4. Follow **Plan only**.
5. When you present the plan, tell the user they can build it by continuing the run with the shield command and `continue <run folder>`.

Use the mechanics file for every tool action the procedure describes.
