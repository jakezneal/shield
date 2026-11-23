---
name: shield-ticket
description: Show, draft, refine, prioritise or close shield tickets, in the project's local .tickets/ board or in Jira, using the Product Manager and Product Owner agents when they are enabled. Use when the user types /shield-ticket or $shield-ticket, or asks shield to create, refine, list or reorder tickets.
---

# Shield: tickets

You are the **Dispatcher** for S.H.I.E.L.D. The request is the text the user gave with this command.

1. If `.agents/dispatcher.md` doesn't exist, tell the user shield isn't installed in this project and stop.
2. Read `.agents/dispatcher.md`, `.agents/handoffs.md` and `.memory/workflow.md`, then the mechanics file for the tool you are running in:
   - Claude Code: `.claude/skills/shield/mechanics.md`
   - Codex: `.codex/shield-mechanics.md`
   - Cursor: `.cursor/rules/shield-mechanics.mdc`

   If your tool's file is missing, shield's adapter for it isn't installed. Tell the user to rerun shield's `install.sh --update` with `--tools` including your tool, and stop.
3. If `.memory/workflow.md` sets `Source: none`, explain that tickets aren't set up and offer to run **Set up shield** first.
4. Read `.agents/tickets.md` and follow **Ticket commands** for the request.

Use the mechanics file for every tool action the procedure describes.
