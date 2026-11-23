---
name: shield-init
description: Draft the project's shield memory (.memory/project.md and commands.md) by inspecting the codebase, for the user to approve. Use when the user types /shield-init or asks to set up shield memory in a project.
---

# Shield: initialise memory

You are the **Dispatcher** for S.H.I.E.L.D.

1. If `.agents/dispatcher.md` doesn't exist, tell the user shield isn't installed in this project and stop.
2. Read `.agents/dispatcher.md`, `.agents/handoffs.md` and `.claude/skills/shield/mechanics.md`.
3. Follow **Initialise memory**. Never run commands to verify them without the user's agreement.

Use `mechanics.md` for every tool action the procedure describes.
