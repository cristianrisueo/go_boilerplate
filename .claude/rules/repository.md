---
paths:
  - "internal/**/repository.go"
  - "internal/**/repository*_test.go"
---

# Repository rules

Loaded when working on a feature's `repository.go` or its tests.

## Project requirement

**Every SQL statement on `users` includes the tenant: `tenant_id = $n` in the
`WHERE` clause of every `SELECT`, `UPDATE` and `DELETE`, and the tenant value
in every `INSERT`. There are no exceptions.**

Every repository method that receives an `id` also receives the tenant.

## Data access conventions

- `pgx/v5` with `pgxpool`. Hand-written SQL, always with placeholders
  (`$1`, `$2`); never build SQL with string concatenation or `fmt.Sprintf`.
- List columns explicitly; never `SELECT *`.
- Use `RETURNING` to get the stored row back from `INSERT` and `UPDATE`.
- Pass the caller's `ctx` to every query.
- Close what you open: prefer `pgx.CollectRows`; otherwise `defer rows.Close()`
  and check `rows.Err()`.
- Translate database errors into the feature's domain errors here, and only
  here:
  - `pgx.ErrNoRows` → the feature's "not found" error
  - `pgconn.PgError` with code `23505` → the feature's "already exists" error
  - anything else → wrap with context: `fmt.Errorf("update order: %w", err)`
- Uniqueness comes from the constraint. Never check existence before an
  insert or update to avoid a duplicate.
- A row that breaks the project requirement above behaves exactly like a
  missing row.

## Operation-specific rules (spec §6.6–§6.8)

- **List** orders by `created_at, id`. The `id` tie-breaker is mandatory.
- **Update** is one statement conditioned on `id`, `tenant_id` and `version`.
  On 0 rows, check existence in the same tenant: missing → `ErrUserNotFound`,
  present → `ErrVersionConflict`. No `SELECT ... FOR UPDATE`.
- **Delete** is `DELETE ... WHERE id = $1 AND tenant_id = $2`; 0 rows →
  `ErrUserNotFound`.
- Domain errors: `ErrUserNotFound` (not found), `ErrEmailExists` (already
  exists), `ErrVersionConflict`.

## Tests

- Real PostgreSQL through `testdb.New(t)`; no doubles.
- Every operation affected by an invariant of spec §5 has a repository test
  for it (plan §5.2), and asserts that the other data is unchanged.
