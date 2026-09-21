<!--
SPEC TEMPLATE — Go backend boilerplate

This template is the contract for `/scaffold-project`. The specs are filled
in either by `/design-project` or by hand, in a chat, following this
template. `/scaffold-project` then reads them and generates everything else
from them: `docs/sprints-plan.md`, `docs/sprints-debt.md`, `docs/reports/`,
the "Project rules" section of `CLAUDE.md` and `.claude/rules/repository.md`.

How to use it:
- Copy to docs/project-specs.md and fill every section. Write in English.
- Every section must be present, with the same numbering. CLAUDE.md, the
  skills and the sprint plan cite sections by number (§5, §6.1, §6.3, §7,
  §9, §12.3).
- Never remove a section. If it does not apply, write "Not applicable."
  so the agent knows it was considered, not forgotten.
- A section marked REQUIRED in its own comment may not say "Not
  applicable": `/scaffold-project` generates from it. They are §1 (module
  path), §5, §6.2, §6.3, §7, §8.2, §9, §12.3 and §13.3.
- Subsections marked "fixed" keep their number and title.
- Delete these comments when the spec is final.
-->

# <project-name> — Specification

> **Status: immutable.** This document is the system of record for what the
> service does and how it is built. It is never edited during a sprint.
> Between sprints the developer or the architect may change it and then
> re-run `/scaffold-project`, which regenerates only the pending part of the
> plan and the derived rules. Every change is recorded in §14.1.

## 1. Purpose

<!-- What the service is and why it exists, in a few lines.
     Include the Go module path. REQUIRED: the module path. -->

Go module: `github.com/<owner>/<project>`

## 2. Scope

### In scope

<!-- Capabilities that will be built. One bullet each. -->

### Out of scope

<!-- What will NOT be built, even if it seems natural. The builder uses
     this list to avoid widening the scope; the auditor uses it for A8. -->

## 3. Assumptions and known limitations

<!-- Accepted weaknesses. The auditor must not report them as defects. -->

| # | Assumption / limitation | Consequence |
|---|---|---|
| A1 | | |

## 4. Domain model

<!-- One subsection per entity, then validation. Add more subsections if
     needed (for example, backward compatibility of a field). -->

### 4.1 <Entity>

| Column | Type | JSON | Notes |
|---|---|---|---|
| | | | |

Constraints and indexes:

- 

### 4.2 Validation and normalization

| Input | Rule | On failure |
|---|---|---|
| | | |

## 5. Invariants

<!-- REQUIRED. Rules that admit NO exceptions: data isolation, security,
     integrity, idempotency. go-reviewer treats every rule here as blocking,
     and the "Project rules" section of CLAUDE.md is derived from this one.

     Use the format that makes an invariant checkable against a diff:
     - Numbered I1…In, one invariant per bullet.
     - Each written as a prohibition on what code may do, not as a property
       of the system: "no SELECT decides whether an INSERT happens", not
       "the system never double-books".
     - Each naming the database constraint or object that enforces it, when
       one exists. -->

Rules that admit no exceptions.

- **I1.** No `SELECT` decides whether an `INSERT` happens: a duplicate is
  rejected by the unique constraint `<constraint_name>` on `<table>`.

## 6. API

<!-- The contract exposed to clients: HTTP, gRPC or events.
     6.1–6.3 are fixed. Add one subsection per feature from 6.4 on
     (request bodies, representations, pagination, concurrency, …). -->

### 6.1 Response format

<!-- fixed. Envelope or message shape, success and error, and its
     exceptions. State that errors never expose internal details. -->

### 6.2 Operations

<!-- fixed, REQUIRED. Endpoints, RPCs or consumed/published events. -->

| Method | Path | Success | Errors |
|---|---|---|---|
| | | | |

### 6.3 Error catalogue

<!-- fixed, REQUIRED. Every error code the service can return. Codes are
     unique snake_case strings and the list is closed: a code that is not in
     this table is never returned. The test plan requires each code to be
     provoked by at least one test. -->

| Code | HTTP | When |
|---|---|---|
| | | |

### 6.4 <Feature-specific subsection>

## 7. Tech stack

<!-- REQUIRED. Versions and the CLOSED list of third-party dependencies.
     Adding a dependency not listed here is out of scope in every sprint. -->

| Concern | Choice |
|---|---|
| Language | Go <version> |
| HTTP | |
| Database | PostgreSQL <version> |
| Driver | |
| Migrations | `github.com/golang-migrate/migrate/v4` — **fixed**, because the targets of §12.3 depend on it. |
| Logging | `log/slog` |
| Tests | `testing` and `net/http/httptest` |

No other third-party dependencies.

## 8. Architecture and conventions

### 8.1 Layout

<!-- How code is grouped (for example, package by feature) and the
     responsibility of each file in a feature. -->

### 8.2 Dependencies

<!-- REQUIRED. Allowed imports between layers and packages, where
     components are wired together, and the rule for introducing
     interfaces. -->

### 8.3 Errors

<!-- Domain errors, wrapping, and mapping to the error catalogue (§6.3). -->

### 8.4 Context

<!-- How context.Context is passed and where context.Background() is
     allowed. -->

### 8.5 Style

<!-- gofmt, go vet, doc comments, naming. -->

## 9. Directory structure

<!-- REQUIRED. The planned tree and one line per file or directory. The
     auditor checks the scope of each sprint against it (A8). -->

```
<project>/
├── cmd/
├── internal/
├── pkg/
├── migrations/
├── docs/
│   ├── project-specs.md
│   ├── sprints-plan.md
│   ├── sprints-debt.md
│   └── reports/
├── .claude/
├── CLAUDE.md
├── Dockerfile
├── docker-compose.yml
├── Makefile
└── go.mod
```

| Path | Responsibility |
|---|---|
| | |

## 10. Configuration and runtime

### 10.1 Environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| | | | |

### 10.2 Startup sequence

<!-- Numbered steps, and what happens when one fails. -->

### 10.3 Shutdown

<!-- Signals, grace period, order in which resources are closed. -->

### 10.4 Logging

<!-- What is logged and what is not. -->

## 11. Database migrations

<!-- Required by .claude/hooks/guard.sh and the postgres-migrations skill.
     Keep the rules below; fill the planned migrations. -->

- File names: `NNNNNN_description.up.sql` and `NNNNNN_description.down.sql`,
  sequential with six digits.
- New migrations are created **only** with
  `make migrate-new name=<description>`.
- A migration that has been committed is **never edited or deleted**. Any
  change goes in a new migration.
- Every `up` has a `down` that reverts it.

Planned migrations:

| Migration | Up | Down |
|---|---|---|
| `000001_<description>` | | |

## 12. Local environment

### 12.1 Dockerfile

<!-- Build and runtime stages, base images, user, exposed port. -->

### 12.2 docker-compose.yml

| Service | Definition |
|---|---|
| `db` | |
| `api` | |

### 12.3 Makefile

<!-- fixed, REQUIRED. The hooks and skills call these targets. All of them
     must exist with this meaning; add project targets below them. -->

| Target | Command | Notes |
|---|---|---|
| `up` | `docker compose up -d --build --wait` | Starts every service. |
| `down` | `docker compose down` | Never with `-v`. |
| `reset` | `docker compose down -v` then `up` | Wipes all data. **Developer only.** |
| `check` | `gofmt -l .` (fails if it prints anything) and `go vet ./...` | |
| `test-short` | `go test -short -count=1 ./...` | No database, no Docker, no network. |
| `test` | start `db`, then `go test -race -count=1 ./...` | Full suite. |
| `migrate-new` | `go tool migrate create -ext sql -dir migrations -seq -digits 6 $(name)` | Fails if `name` is empty. |
| `migrate-up` | `go run -tags postgres github.com/golang-migrate/migrate/v4/cmd/migrate -path migrations -database $(DATABASE_URL) up` | **fixed.** Applies every pending migration. |
| `migrate-down` | `go run -tags postgres github.com/golang-migrate/migrate/v4/cmd/migrate -path migrations -database $(DATABASE_URL) down 1` | **fixed.** Reverts the last migration. |

`go tool migrate` cannot apply migrations: golang-migrate builds its
database drivers behind build tags and `go tool` accepts no build flags, so
`migrate-up` and `migrate-down` go through `go run -tags postgres`.
`DATABASE_URL` is exported only to the full-tier targets, never to
`test-short`.

## 13. Testing strategy

### 13.1 Test tiers

<!-- What runs in test-short (pure code, used by the Stop hook) and what
     runs in test (real dependencies). State the policy on test doubles. -->

| Tier | Command | What runs |
|---|---|---|
| Short | `make test-short` | |
| Full | `make test` | |

### 13.2 Test data

<!-- How tests isolate their data and prepare the schema. -->

### 13.3 Mandatory cases

<!-- REQUIRED. Behaviours that must have a test: one bullet per case, each
     named so an acceptance criterion can cite it, and at least one case per
     invariant of §5. -->

## 14. Change log

### 14.1 Revisions

<!-- One dated entry per change to this document: what changed, why, and
     which already-built behaviour it invalidates. -->

| Date | Change | Why | Invalidates |
|---|---|---|---|
| | | | |

### 14.2 Decisions

<!-- Deliberate choices, so that nobody "fixes" them later. A rejected
     alternative goes here too, with the reason it was rejected. -->

| Decision | Choice | Main reason |
|---|---|---|
| | | |
