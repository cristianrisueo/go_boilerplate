# <project-name>

<One line: what this service is.> Go service built sprint by sprint by
Claude Code.

## Sources of truth

- `docs/project-specs.md` — what the service does and how it is built.
- `docs/sprints-plan.md` — how each sprint is executed, audited and verified.
- `docs/reports/sprint-NN.md` — what each sprint delivered.
- `docs/sprints-debt.md` — non-blocking audit findings, cleared in the
  hardening sprint.
- `.claude/templates/` — the standard shape of those documents.

Below, "specs" means `docs/project-specs.md` and "plan" means
`docs/sprints-plan.md`, cited by section number.

The specs and the plan are immutable: never edit them. Read the parts you
need when you need them. If the code and the specs disagree, stop and report
it; do not silently follow either.

## Roles

Sessions start through a launcher that sets `CLAUDE_ROLE`:

| Role        | Launcher                   | Entry point        |
| ----------- | -------------------------- | ------------------ |
| designer    | `.claude/bin/design.sh`    | `/design-project`  |
| implementer | `.claude/bin/implement.sh` | `/start-sprint NN` |
| auditor     | `.claude/bin/audit.sh`     | `/audit-sprint NN` |
| developer   | plain `claude`             | maintenance        |

Never merge, push, or commit on `main`. In a role session, never edit
`.claude/`: the architect is the only role that writes `CLAUDE.md` and
`.claude/rules/`, and no role writes the permissions, hooks, launchers,
skills or templates. Those are the enforced layer, and the plain developer
session is the one that changes the configuration.

## Commands

The Makefile targets of specs §12.3:

| Command                               | Use                                         |
| ------------------------------------- | ------------------------------------------- |
| `make check`                          | gofmt + go vet                              |
| `make test-short`                     | Pure tests, no database                     |
| `make test`                           | Full suite with race detector (starts `db`) |
| `make up` / `make down`               | Start / stop the services                   |
| `make migrate-new name=<description>` | The only way to create a migration          |

Never run `make reset` or `docker compose down -v`: they wipe the database.

## Workflow rules

- Stay inside the sprint scope. If a criterion cannot be met within scope,
  stop and say so in the report. Never widen the scope to make a test pass.
- Tests first. Before writing a test, create compiling stubs (zero values or
  an explicit "not implemented" error) so the red run fails on assertions,
  never on compilation.
- Existing `*_test.go` files are never modified or deleted once their
  sprint has merged into `main`. Within the current, unmerged sprint, a test
  file created earlier in that same sprint may still be edited or deleted.
  New tests go in new files (for example `handler_list_test.go`); names
  beyond the tree in specs §9 are expected.
- A `.claude/hooks` message that blocks an action is final. Do not look for
  another way to do the same thing; adapt the approach or report it.
- Probes (plan §6) are the only time you attempt a forbidden action on
  purpose: exactly the listed action, once.

## Go conventions

- `context.Context` is the first parameter of every service and repository
  method, and it is passed down to every database call.
  `context.Background()` only in `cmd/` and tests.
- Errors: wrap with context (`fmt.Errorf("get order: %w", err)`), compare
  with `errors.Is`, define domain errors as package-level variables.
- Unexpected errors are logged and returned to clients as a generic message.
  Never expose SQL, driver errors or stack traces.
- Concrete types. No interface until a second implementation exists; never an
  interface created only for tests.
- Every exported identifier has a doc comment.
- Tests: standard `testing` and `httptest` only. No mocks, fakes, stubs or
  assertion libraries. Table-driven with `t.Run` when a function has several
  cases. `t.Parallel()` unless the test needs exclusive state. No `time.Sleep`.
- API tests decode the response and assert individual fields; never compare
  whole bodies as strings.
- Name tests `Test<Unit>_<Method>_<Case>`.

## Database conventions

- A migration that exists on `main` is never edited, moved or deleted.
  Every `up` has a `down`.
- Tests that verify a schema run on a scratch database migrated with an
  `fs.FS` containing only the migrations they verify, so later migrations
  never break them.
- Uniqueness is enforced by database constraints, never by a prior existence
  check.

## Project rules

<!-- ARCHITECT: write this section after the specs and the plan are approved,
     never before. One rule per invariant of specs §5, stated so that
     go-reviewer and the auditor can check it by reading a diff. Add the
     import rules of specs §8.2 and how database tests get their pool and
     isolate their data (plan §5.4). Keep it short: rules nobody can check
     are noise. Delete this comment when done. -->

These rules are specific to this project. `go-reviewer` and the auditor
check them in addition to the conventions above.

1. **Invariants** (specs §5). <One rule per invariant, with no exceptions.>
2. **Responses** use the response format of specs §6.1 and the error
   catalogue of specs §6.3.
3. **Dependencies.** No third-party dependency beyond specs §7.
   <Import rules of specs §8.2, and the only place where components are
   wired together.>
4. **Database tests** get their pool from <test database helper> and
   isolate their data <how>.
