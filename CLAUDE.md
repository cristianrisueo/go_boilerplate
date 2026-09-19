# tenant-poc

Multi-tenant users CRUD. Go service built sprint by sprint by Claude Code.

## Sources of truth

- `docs/spec.md` — what the service does and how it is built.
- `docs/sprints/plan.md` — how each sprint is executed, audited and verified.
- `docs/sprints/reports/sprint-NN.md` — what each sprint delivered.
- `docs/templates/` — the standard shape of those three documents.

These documents are immutable: never edit them. Read the parts you need when
you need them. If the code and the spec disagree, stop and report it; do not
silently follow either.

## Roles

Sessions start through a launcher that sets `CLAUDE_ROLE`:

| Role        | Launcher                   | Entry point        |
| ----------- | -------------------------- | ------------------ |
| implementer | `.claude/bin/implement.sh` | `/start-sprint NN` |
| auditor     | `.claude/bin/audit.sh`     | `/audit-sprint NN` |
| developer   | plain `claude`             | maintenance        |

Never merge, push, or commit on `main`. Never edit `.claude/` or `CLAUDE.md`.

## Commands

The Makefile targets of spec §12.3:

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
  beyond the tree in spec §9 are expected.
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

These rules are specific to this project. `go-reviewer` and the auditor
check them in addition to the conventions above.

1. **Invariants** (spec §5). Tenant isolation: every SQL statement on
   `users` includes the tenant: `tenant_id = $n` in every `SELECT`, `UPDATE`
   and `DELETE`, and the tenant value in every `INSERT`. No exceptions.
   A user of another tenant is `404`, never `403`. The middleware stores the
   tenant in the context; handlers pass it explicitly as a `uuid.UUID`
   argument to the service and the repository.
2. **Responses** use the response format of spec §6.1 and the error
   catalogue of spec §6.3.
3. **Dependencies.** No third-party dependency beyond spec §7.
   `pkg/` never imports `internal/` or `migrations`. `cmd/api/setup.go` is the
   only place that wires components together. Schema tests live in
   `migrations/` as package `migrations_test`, because `pkg/database` cannot
   import `internal/testdb` or `migrations`.
4. **Database tests** get their pool from `testdb.New(t)` and isolate their
   data with a random tenant (`uuid.New()`) per test. Scratch databases come
   from `testdb.NewScratchDatabase(t)`.
