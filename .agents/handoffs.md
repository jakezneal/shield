# Handoffs

The contract between the Dispatcher and the roles: where run files live, what goes in a dispatch brief, what every report looks like, and what the status words mean. Every role reads this file.

## Run folder

Each run gets `.shield/runs/<YYYY-MM-DD>-<slug>/`. The folder is gitignored. Only the Dispatcher writes to it.

| File | Written after | Contents |
|---|---|---|
| `brief.md` | Intake | Request verbatim, branch, base commit, user decisions and approvals |
| `plan.md` | Plan | Architect's plan |
| `design.md` | Design | Designer's brief (UI work only) |
| `develop-<n>.md` | Develop | Developer's report for round `<n>` |
| `review-<n>.md` | Review | Reviewer's report for round `<n>` |
| `test-<n>.md` | Test | Tester's report for round `<n>` |
| `summary.md` | Wrap-up | Outcome, evidence, open issues, memory updates, suggested commit message |

Round 0 is the first implementation. Fix rounds are 1 and 2.

Roles read earlier files from the run folder themselves rather than relying on what the Dispatcher pastes into the brief.

## Dispatch brief

Every dispatch gives the role:

- Its role name and role file: `.agents/<role>.md`
- The run folder path, and which files in it to read
- The round number
- For fix rounds: the finding IDs to address
- The skills `plan.md` assigns to this role, or `None`
- Anything the user decided since the last report

Keep briefs short and point to files. Do not paste whole reports.

## Report format

Every report starts with this header:

```
Role: <role>
Status: <status word>
Round: <n>
Model: <model name if known, otherwise Unknown>
```

The role's own sections follow (see each role file). Every report ends with:

```
Memory updates: <durable facts proposed for .memory/, or None>
```

Return the report as your final message. The Dispatcher saves it.

## Status words

| Status | Used by | Meaning | Dispatcher's next step |
|---|---|---|---|
| `PLAN_READY` | Architect | Plan is complete | Checkpoint with the user |
| `DRAFT_READY` | Architect | Memory drafts are ready (init only) | Show the user |
| `NEEDS_INPUT` | Architect, Designer | Blocking questions only the user can answer | Ask the user, return the answers |
| `BRIEF_READY` | Designer | Design brief is complete | Develop |
| `DONE` | Developer | Implemented, focused checks pass | Review |
| `DONE_WITH_CONCERNS` | Developer | Implemented, with doubts the Reviewer should look at | Review, passing on the concerns |
| `READY_FOR_TEST` | Reviewer | Meets the plan, no blocker or major findings | Test |
| `NEEDS_CHANGES` | Reviewer | At least one blocker or major finding | Fix loop |
| `PASS` | Tester | Fresh verification passed | Wrap-up |
| `FAIL` | Tester | Verification failed | Fix loop |
| `NEEDS_CONTEXT` | Developer, Reviewer, Tester | Missing information needed to continue | Answer from the plan or memory, or ask the user |
| `BLOCKED` | Any role | Cannot proceed: conflicting requirements, wrong plan, missing environment | Stop and tell the user |

## Findings

Reviewers number findings `R1`, `R2` and so on; Testers use `T1`, `T2`. A finding keeps its ID across rounds.

Each finding gives:

- **Severity**: `blocker` (wrong, unsafe or broken), `major` (must fix before this ships) or `minor` (worth doing, does not block)
- **Location**: `path/to/file:line` where possible
- **Problem**: what is wrong and why it matters
- **Suggested fix**: or the decision that is needed

Only `blocker` and `major` findings send work back to the Developer. `minor` findings go in the summary for the user to decide.

## Fix loop limits

- At most 2 fix rounds after the first implementation.
- If a finding comes back unchanged after a fix, the loop stops early.
- If the Developer disputes a finding, the user decides.
- When the loop stops, the Dispatcher reports the open findings and asks the user how to proceed.

## Rules for every role

1. Read your role file and this file before anything else.
2. Read the `.memory/` files relevant to your job. They hold verified project knowledge: commands that work, decisions already made, known traps.
3. Do your role's job only. The Architect does not code, the Developer does not approve its own work, the Reviewer and Tester do not fix.
4. Do not edit anything in `.shield/` or `.memory/`. Propose memory updates in your report instead.
5. Never commit, push, stash, reset, switch branches or otherwise change git state.
6. Never put secrets, credentials, tokens or personal data in a report. If you find any in the code, flag the location without repeating the value.
7. Evidence over assertion. Say a check passed only if you ran it in this context and saw it pass. "Not run" and "not verified" are honest, acceptable answers.
8. If you cannot continue, report `NEEDS_CONTEXT` or `BLOCKED` with the smallest decision or thing you need. Do not guess.
9. Write in the conventions set in `.memory/project.md`. If none are set, use British English.
