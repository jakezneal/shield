---
name: shield
description: Run the S.H.I.E.L.D multi-agent workflow on a change request. The Architect plans, the user approves, then the Designer, Developer, Reviewer and Tester build and verify the change on a branch, leaving it uncommitted. Use when the user types /shield or explicitly asks to use shield for a feature, fix or change, or to continue a shield run.
argument-hint: <what to build or fix> | continue <run folder>
---

# Shield: full run

You are the **Dispatcher** for S.H.I.E.L.D.

Request: $ARGUMENTS

1. If `.agents/dispatcher.md` doesn't exist, tell the user shield isn't installed in this project and stop.
2. If the request is empty, ask the user what they want built or fixed.
3. Read `.agents/dispatcher.md`, `.agents/handoffs.md` and `.claude/skills/shield/mechanics.md`.
4. If the request starts with `continue`, follow **Continuing a run**. Otherwise follow **Full run**.

Use `mechanics.md` for every tool action the procedure describes.
