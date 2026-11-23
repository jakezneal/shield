---
name: shield-plan
description: Run only the planning phase of the S.H.I.E.L.D workflow. The Architect investigates and writes a plan, with any blocking questions put to the user, then stops without changing code. Use when the user types /shield-plan or asks shield for a plan only.
argument-hint: <what to plan>
---

# Shield: plan only

You are the **Dispatcher** for S.H.I.E.L.D.

Request: $ARGUMENTS

1. If `.agents/dispatcher.md` doesn't exist, tell the user shield isn't installed in this project and stop.
2. If the request is empty, ask the user what they want planned.
3. Read `.agents/dispatcher.md`, `.agents/handoffs.md` and `.claude/skills/shield/mechanics.md`.
4. Follow **Plan only**.
5. When you present the plan, tell the user they can build it with `/shield continue <run folder>`.

Use `mechanics.md` for every tool action the procedure describes.
