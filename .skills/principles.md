# Engineering Principles

Practices every shield role follows, whatever the stack. Role files say how each role applies them.

## Planning

- Keep runs small enough to review in one sitting. Split large requests into runs that each leave the project working.
- Write decisions down, in the plan or in `.memory/decisions.md`, rather than leaving them in conversation.
- Give each role exactly the context it needs: the run folder, the files to read, the findings to address.
- If a role reports `NEEDS_CONTEXT`, `DONE_WITH_CONCERNS` or `BLOCKED`, change the context, the plan or the size of the work before retrying. Retrying unchanged rarely helps.

## Testing and verification

- For behaviour changes, test first: a failing test, the expected failure, the minimal code, a passing test.
- Never claim something works without fresh evidence from a command you ran.
- Prefer deterministic tests with precise assertions. Control clocks, random values, network calls and storage in tests.
- Assert on the meaningful result, not a transformed version that hides it.
- Use snapshot tests deliberately, for stable output, and update them through the project's own workflow.
- For bug fixes, reproduce the original problem first and confirm afterwards that it has gone.

## Debugging

- Reproduce before fixing.
- Read the error and the logs closely.
- Compare with similar code in the project that works.
- Test one hypothesis at a time, with the smallest possible change.
- Fix the root cause, not the symptom.
- Fix environment and build problems before debugging application code.

## Design and UI

- Decide design intent before implementation details.
- Reuse the existing design system before adding components or tokens.
- Accessibility is part of done: labels, contrast, keyboard and focus behaviour, text resizing and target size (WCAG 2.2 AA unless the project says otherwise).
- Cover every state: loading, empty, error and edge cases, not just the happy path.

## Security

- Treat all external input as untrusted. Validate at boundaries; use parameterised queries and proper output encoding.
- Never put secrets, credentials or personal data in code, tests, logs, reports or memory. Use the project's secrets mechanism.
- Give code and services the least access they need.
- Before adding a dependency, check it is maintained, widely used and has a licence compatible with the project. Record why it is needed.
- Make security implications of a change explicit in plans and reports.

## Dependencies and data

- Prefer explicit dependencies over hidden globals, so they can be controlled in tests.
- Keep persistence type-safe or schema-aware where the stack allows.
- Treat migrations and data changes as high risk: plan the rollback.

## Hygiene

- Use the commands recorded in `.memory/commands.md` rather than rediscovering them.
- Use the narrowest command that answers the question or proves the change.
- Preserve user-owned configuration and project state.
- Make setup and installer changes idempotent, and document how to undo them.
- Before handing over, check `git status` for accidental files and missing new files.
- Record durable, verified knowledge in `.memory/` so no one has to rediscover it.
