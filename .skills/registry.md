# Skill Registry

How the Architect chooses skills for each role. A "skill" here is any reusable guidance an agent can load: a Claude Code skill or plugin, a Copilot or Cursor instruction file, a document in this repository, a note in `.skills/local.md`, or a project tool such as an MCP server's tools listed in `.skills/tools.md`.

## How to assign skills

1. Identify the language, framework, platform and kind of task from the request, the code and `.memory/project.md`.
2. Check `.skills/local.md` first. Project-specific entries win. Check `.skills/tools.md` for the project tools each role may use.
3. Check which skills your tool actually has available. Never assign a skill that isn't installed, or a project tool that `.skills/tools.md` doesn't give that role.
4. Use the routing below to decide which roles need which kind of skill. Assign only what each role needs; not every role needs every skill.
5. Record the result in the plan's `## Skills` section, per role, or `None`.

No skill is ever mandatory unless `.skills/local.md` or the user says so. If nothing fits, write `None`; the role files and `principles.md` are enough on their own.

## Routing by task

| Task | Architect | Designer | Developer | Reviewer | Tester |
|---|---|---|---|---|---|
| New feature | Planning, domain | UI skills if UI changes | Framework, test-first | Code review | Framework test tools |
| Bug fix | Debugging (require a reproduction) | | Debugging, test-first | Root-cause check | Reproduce the original symptom |
| UI or UX change | Mark Design required | Design system, accessibility, design tooling | Frontend framework | Accessibility, visual consistency | Browser or UI testing |
| Refactor | Architecture | | Framework | Behaviour unchanged | Regression suite |
| Performance | Profiling | | Profiling, framework | Benchmarks are fair | Before and after measurements |
| Security fix | Threat modelling | | Secure coding | Security review | Exploit no longer works |
| Data or migration | Data modelling, rollback | | Database, migrations | Data safety | Migration up and down on test data |
| Dependency upgrade | Changelog research | | Package manager | Licence and breaking changes | Full suite |
| Infrastructure or CI | Infrastructure | | IaC, CI tools | Least privilege, secrets | Dry runs or plan output |
| Documentation | | | Docs conventions | Accuracy against the code | Examples run |

## Routing by stack

Look for skills matching the project's stack and assign them by role:

- **Web frontend** (React, Vue, Angular, Svelte and so on): component and state patterns for Developer and Reviewer; browser testing for Tester; design system and accessibility for Designer.
- **Backend and APIs**: framework, API design and data access for Architect and Developer; API contract and security for Reviewer; integration testing for Tester.
- **Mobile** (iOS, Android, cross-platform): platform UI guidelines for Designer; platform build and simulator tools for Developer and Tester.
- **Data and machine learning**: data validation and reproducibility for every role; notebook or pipeline tooling for Developer and Tester.
- **Infrastructure as code**: provider conventions for Developer; policy and least-privilege checks for Reviewer; plan or dry-run output for Tester.
- **Libraries and CLIs**: public API stability and versioning for Architect and Reviewer; packaging and install smoke tests for Tester.

## Design tooling

When UI work has design sources, the Designer may use whatever tooling is available, such as a Figma connection, design-system documentation, a component library or screenshots. Name the tool in the Designer's skills if the project has one. If none is available, the Designer works from the codebase and says so.
