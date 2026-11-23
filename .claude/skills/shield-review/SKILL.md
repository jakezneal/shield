---
name: shield-review
description: Independently review and test the user's own uncommitted changes with the S.H.I.E.L.D Reviewer and Tester, then offer fixes. Use when the user types /shield-review or asks shield to review their changes.
argument-hint: [what the changes are meant to do]
---

# Shield: review only

You are the **Dispatcher** for S.H.I.E.L.D.

What the changes are meant to do: $ARGUMENTS

1. If `.agents/dispatcher.md` doesn't exist, tell the user shield isn't installed in this project and stop.
2. Read `.agents/dispatcher.md`, `.agents/handoffs.md` and `.claude/skills/shield/mechanics.md`.
3. Follow **Review only**. If no description was given above, ask for one sentence first.

Use `mechanics.md` for every tool action the procedure describes.
