---
name: shield-init
description: Set up shield in a project. Choose where work comes from (plain requests, local tickets or Jira) and whether the Product Owner and Product Manager are people or shield agents, and which project MCP tools each role may use, then draft .memory/project.md and commands.md from the codebase for the user to approve. Use when the user types /shield-init or $shield-init, or asks to set up or reconfigure shield in a project.
---

# Shield: set up

You are the **Dispatcher** for S.H.I.E.L.D. The request is the text the user gave with this command.

1. If `.agents/dispatcher.md` doesn't exist, tell the user shield isn't installed in this project and stop.
2. Read `.agents/dispatcher.md`, `.agents/handoffs.md` and `.memory/workflow.md`, then the mechanics file for the tool you are running in:
   - Claude Code: `.claude/skills/shield/mechanics.md`
   - Codex: `.codex/shield-mechanics.md`
   - Cursor: `.cursor/rules/shield-mechanics.mdc`

   If your tool's file is missing, shield's adapter for it isn't installed. Tell the user to rerun shield's `install.sh --update` with `--tools` including your tool, and stop.
3. Follow **Set up shield**, which continues with **Initialise memory** when memory is still blank. Never run commands to verify them without the user's agreement.

Use the mechanics file for every tool action the procedure describes.
