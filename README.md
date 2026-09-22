# Go Boilerplate

A Claude Code configuration for building Go backend services with AI agents,
sprint by sprint, tests first, with an independent audit of every sprint.

Go Boilerplate is not a code template. It contains no service code: it is the
`.claude/` folder, a `CLAUDE.md` and a `.gitignore` that you copy into an empty
repository. From there, Claude Code designs the project, plans it, builds it
and audits it, while the developer approves, decides and merges.

## What it does

The work is split between three Claude roles and one person:

| Role          | What it does                                                                                                                      |
| ------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| **Architect** | Turns the design into documents: writes the specification and generates the sprint plan and the project rules from it.            |
| **Builder**   | Runs each sprint: writes the tests, watches them fail, implements, verifies and reports.                                          |
| **Auditor**   | Checks each sprint without trusting the builder: re-runs everything, reads every test against its criterion and issues a verdict. |
| **Developer** | Designs, approves, decides when something halts, and merges. Does not write the service code.                                     |

Everything rests on one document, the project specification
(`docs/project-specs.md`). It is written once and everything else is
generated from it.

The configuration decides three things:

- **What Claude knows** — `CLAUDE.md`, path-scoped rules and skills. Advisory:
  Claude reads and follows them.
- **What Claude cannot do** — per-role permissions and a `PreToolUse` guard
  hook. Enforced by Claude Code, not by the model.
- **How its work is checked** — automatic formatting, a hook that refuses to
  end a turn with failing tests, an independent reviewer subagent, and a
  two-round audit of every sprint.

## What's inside

```
.claude/
├── agents/go-reviewer.md        read-only reviewer subagent
├── bin/                         one launcher per role
├── hooks/                       session context, guard, formatter, stop-on-failing-tests
├── roles/                       permissions of each role
├── rules/repository.md          rules loaded only in the data layer
├── skills/                      design-project, scaffold-project, start-sprint,
│                                audit-sprint, postgres-migrations
├── templates/                   specs, sprint plan, sprint report, debt ledger
├── settings.json                project-wide permissions and hook wiring
└── README.md                    full reference for every file
CLAUDE.md                        instructions Claude reads in every session
```

## Quick start

Requirements: `bash`, `git`, `jq`, `go`, `docker` and Claude Code.

**1. Create the repository** — the `main` branch name is required.

```bash
mkdir my-service && cd my-service
git init -b main
# copy .claude/, CLAUDE.md and .gitignore from this repository
chmod +x .claude/bin/*.sh .claude/hooks/*.sh
```

**2. Write the specs** — two routes, same result.

- _In a chat:_ fill in `.claude/templates/project-specs.md` with Claude, save
  it as `docs/project-specs.md`, then run `.claude/bin/architect.sh` and
  `/scaffold-project`.
- _In Claude Code:_ run `.claude/bin/architect.sh` and `/design-project`. The
  architect designs the service with you, writes the specs, stops for your
  approval and then runs `/scaffold-project` itself.

`/scaffold-project` refuses specs that do not follow the template. When they
do, it generates the sprint plan, the debt ledger, `docs/reports/`, the
project rules in `CLAUDE.md` and `.claude/rules/repository.md`. Then commit:

```bash
git add -A && git commit -m "init: specs, sprint plan and agent configuration"
```

**3. Run the sprints** — two terminals.

| Terminal 1 — builder                              | Terminal 2 — auditor                              |
| ------------------------------------------------- | ------------------------------------------------- |
| `.claude/bin/builder.sh`, then `/start-sprint NN` | `.claude/bin/auditor.sh`, then `/audit-sprint NN` |

- `APPROVED` → merge the sprint branch yourself.
- `CHANGES REQUESTED` → `/start-sprint NN` runs the single fix round, then
  `/audit-sprint NN` runs round 2, which only confirms the fixes.
- Round 2 not approved → the sprint halts and the developer decides. There is
  no round 3.

A finding is blocking only if it breaks an acceptance criterion, an invariant
of the specs or a project rule. Everything else goes to the debt ledger and
is cleared in the final hardening sprint.

## Principles

- Every acceptance criterion is machine-verifiable: a named test or a command
  with an expected result.
- Tests first: every sprint shows its tests failing before the implementation.
- At most two audit passes per sprint.
- The specs and the plan never change during a sprint. Between sprints they
  change through one path, and everything derived is regenerated.
- No role can change the configuration that constrains it.

## Learn more

[`.claude/README.md`](.claude/README.md) describes every file in the
configuration, what it does and why it exists.
