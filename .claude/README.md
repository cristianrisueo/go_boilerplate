# Claude Code configuration

Claude writes the code. This configuration decides three things:
**what Claude knows**, **what Claude cannot do**, and **how its work is
checked**. Every file covers one of those three, or helps you get started.

This README is for people. Claude Code does not load it.

## Requirements

### Documents

The configuration expects these documents, at these exact paths and with
the structure of their templates. The skills, permissions and hooks refer
to them.

| Document                    | Purpose                                                       | Written by                          | Follows                              |
| --------------------------- | ------------------------------------------------------------- | ----------------------------------- | ------------------------------------ |
| `docs/project-specs.md`     | What the service does and how it is built. Immutable.         | Developer, with the design chat     | `.claude/templates/project-specs.md` |
| `docs/sprints-plan.md`      | How each sprint is executed, audited and verified. Immutable. | Developer, with the design chat     | `.claude/templates/sprints-plan.md`  |
| `docs/reports/sprint-NN.md` | What each sprint delivered and how it was audited.            | `/start-sprint` and `/audit-sprint` | `.claude/templates/sprint-report.md` |
| `docs/sprints-debt.md`      | What each audit leaves behind as non-blocking debt.           | `/audit-sprint`                     | `.claude/templates/sprints-debt.md`  |

The four templates live in `.claude/templates/`.
The spec and plan templates are used with the design chat, before any code
exists. The report and debt-ledger templates are used by Claude Code on every
sprint. Editing any of them takes a plain `claude` developer session:
`.claude/` is the agent configuration, and `hooks/guard.sh` blocks every
role — including the architect, which may write `CLAUDE.md` and
`.claude/rules/` but never the templates, permissions, hooks, launchers or
skills.

### What the configuration relies on

The configuration cites sections by number and reads headings by name.
**Never remove, rename or renumber them.** If a section does not apply,
write `Not applicable.` inside it.

| Element                                                                         | Used by                                                                                                                               |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| Spec §5 Invariants                                                              | `go-reviewer`, audit check A6, "Project rules" in `CLAUDE.md`                                                                         |
| Spec §6.1 Response format and §6.3 Error catalogue                              | `CLAUDE.md`, audit check A5, test rule T4                                                                                             |
| Spec §7 Tech stack                                                              | Scope rule: no dependency outside this list                                                                                           |
| Spec §9 Directory structure                                                     | Audit check A8                                                                                                                        |
| Spec §12.3 Makefile targets                                                     | `stop-tests.sh`, `guard.sh`, `CLAUDE.md` and both sprint skills (`check`, `test-short`, `test`, `up`, `down`, `reset`, `migrate-new`) |
| Plan §2.1–§2.7, §3, §4, §5, §6                                                  | `/start-sprint` and `/audit-sprint`                                                                                                   |
| Report headings `## Summary`, `## Deviations`, `## Open issues`, `**Verdict:**` | `hooks/session-context.sh`                                                                                                            |

### Tools

The hooks need `bash`, `git`, `jq` and `go` installed locally.

---

## 1. What Claude knows

Everything in this section is **advisory**: Claude reads it and tries to
follow it, but nothing forces it to.

### `CLAUDE.md` (project root)

- **What it does:** the first thing Claude reads in every session. It points
  to the spec and the plan, lists the commands to use, and describes how Go
  is written in this project.
- **Why:** without it, Claude guesses the conventions and every session
  starts from zero.
- **Worth it?** Yes, essential. Its "Project rules" section is the main
  thing to fill in for each project, derived from spec §5.

### `rules/repository.md`

- **What it does:** instructions that are loaded only when Claude works on
  the code that talks to the database (`internal/**/repository.go` and its
  tests).
- **Why:** the data layer is where an agent makes the most expensive
  mistakes (unsafe SQL, a missing access filter). These instructions should
  not take up context while Claude works on other layers. Its "Project
  requirement" is filled in for each project, from spec §5.
- **Worth it?** Yes. Almost every Go backend has a database, and this is the
  only rule we keep.

### `skills/postgres-migrations/SKILL.md`

- **What it does:** explains how to create and test a change to the database
  structure. Claude loads it on its own, only when it needs it.
- **Why:** a bad migration cannot be undone in production. Claude should
  always follow the same procedure.
- **Worth it?** Yes, but it is the least reliable piece: it depends on
  Claude deciding to load it. If it does not, invoke it by hand with
  `/postgres-migrations`.

---

## 2. What Claude cannot do

Everything in this section is **enforced**: Claude Code applies it, not the
model.

### `settings.json`

- **What it does:** rules for every session. It asks for approval before
  editing the spec, the plan or the templates, forbids `git push` and
  `git merge`, and prevents disabling the permission system. It also
  connects the hooks.
- **Why:** these are the project's red lines. They must apply to everyone,
  always.
- **Worth it?** Yes, essential.

How the hooks are connected:

| Event          | When                                     | Filter                     | Script               | Purpose                                    |
| -------------- | ---------------------------------------- | -------------------------- | -------------------- | ------------------------------------------ |
| `SessionStart` | On start, resume, `/clear` or compaction | Always                     | `session-context.sh` | Tell Claude where the project stands       |
| `PreToolUse`   | Before a tool runs                       | Commands, edits and writes | `guard.sh`           | Block forbidden actions before they happen |
| `PostToolUse`  | After a tool runs                        | Edits and writes           | `go-format.sh`       | Format and check the Go just written       |
| `Stop`         | When Claude is about to finish its turn  | Always                     | `stop-tests.sh`      | Do not let it finish with failing tests    |

A script answers with its exit code: `0` means "go ahead"; `2` means
"blocked", and its error message is sent to Claude.

### `hooks/guard.sh`

- **What it does:** before every command or edit, it blocks three things:
  wiping the database (`docker compose down -v`, `make reset`), changing a
  migration that is already on `main`, and committing on `main`.
- **Why:** a permission rule only compares text. This script can reason, for
  example by asking git whether a migration is already on `main`.
- **Worth it?** Yes, essential. It prevents the most expensive mistakes:
  losing data or breaking the database history.

---

## 3. How the work is checked

### `hooks/go-format.sh`

- **What it does:** every time Claude writes a Go file, it formats it with
  `gofmt` and looks for problems with `go vet`.
- **Why:** Claude gets the error immediately and fixes it, without anyone
  asking.
- **Worth it?** Yes. Cheap and useful in any Go project.

### `hooks/stop-tests.sh`

- **What it does:** the builder cannot finish while
  `make test-short` fails.
- **Why:** it turns "the tests must pass" from a request into an obligation.
- **Worth it?** Yes, essential. It is the Definition of Done, enforced.

### `agents/go-reviewer.md`

- **What it does:** a second Claude, unable to edit, that reviews the code
  against Go conventions, spec §5 and the "Project rules" of `CLAUDE.md`,
  and returns a list of problems.
- **Why:** whoever writes the code is not a good judge of it. This reviewer
  has not seen how the code was written.
- **Worth it?** Yes, essential. You can also call it directly:
  "Use the go-reviewer subagent on the uncommitted changes."

### `skills/audit-sprint/SKILL.md`

- **What it does:** audits a finished sprint with checks A1–A10 of plan §4.
  It re-runs the verification, checks that each test really tests what it
  claims, runs `go-reviewer`, and appends the verdict to the sprint report
  using section 2 of `.claude/templates/sprint-report.md`.
- **Why:** it does not trust what the builder says; it checks it.
- **Worth it?** Yes, if you work in sprints. It is half of the process.

---

## 4. How the work is done

### `skills/start-sprint/SKILL.md`

- **What it does:** runs a sprint of the plan from start to finish: branch,
  tests first, code, verification, probes, report and commit. The report
  follows section 1 of `.claude/templates/sprint-report.md`. If the audit
  requested changes, it runs the fix round instead and appends section 3.
- **Why:** it replaces copying prompts from a chat. The process lives in the
  repository, so anyone can run it.
- **Worth it?** Yes, if you work in sprints. It is the other half of the
  process.

### `templates/sprint-report.md`

- **What it does:** defines the exact shape of a sprint report in three
  parts: the initial report, an audit round and a fix round.
- **Why:** three pieces depend on that shape: `/start-sprint` writes it,
  `/audit-sprint` appends to it, and `session-context.sh` reads it. One file
  keeps them in sync; change the format there and nowhere else.
- **Worth it?** Yes, if you work in sprints. Without it, a heading written
  slightly differently silently breaks the session context.

### `templates/sprints-debt.md`

- **What it does:** defines the debt ledger, `docs/sprints-debt.md`: one row
  per non-blocking audit finding, with its sprint, location and status.
  `/audit-sprint` appends to it in step 4b.
- **Why:** a non-blocking finding is real, but not worth halting a sprint
  for. Without a ledger it is written once into a report nobody opens again,
  and never fixed.
- **Worth it?** Yes, if you work in sprints. It is what makes the hardening
  sprint possible: the list of what to clean up is already written.

### `hooks/session-context.sh`

- **What it does:** when a session starts, or after `/clear`, it tells
  Claude the current branch, the latest commits and how the last sprint
  ended, taken from the report headings defined in the template.
- **Why:** the conversation is cleared on every sprint. Without this, Claude
  would start without knowing where things stand.
- **Worth it?** Yes, although it is the least critical hook: if it fails,
  Claude still works, it just finds its way less easily.

### `roles/architect.json`, `roles/builder.json` and `roles/auditor.json`

- **What they do:** the permissions of each role. The architect writes the
  documents, `CLAUDE.md` and `.claude/rules/`, and no code; the builder can
  build and test without asking; the auditor can only read, verify and write
  its verdict.
- **Why:** the auditor cannot touch the code, even if it tried.
- **Worth it?** Yes, if you use two terminals. With a single terminal they
  are not needed.

### `bin/architect.sh`, `bin/builder.sh` and `bin/auditor.sh`

- **What they do:** start Claude with the right role, permissions and mode,
  so you do not have to remember any of it.
- **Why:** the role files do nothing on their own; something has to load
  them. These scripts always do it the same way.
- **Worth it?** Yes, they go together with the roles: remove one and the
  other is useless.

How to use them, from the project root:

| Session     | Start                                           | Then run           |
| ----------- | ----------------------------------------------- | ------------------ |
| architect   | `.claude/bin/architect.sh` (before sprint 00)   | `/design-project`  |
| 1 — builder | `.claude/bin/builder.sh`                        | `/start-sprint NN` |
| 2 — auditor | `.claude/bin/auditor.sh` (on the sprint branch) | `/audit-sprint NN` |

