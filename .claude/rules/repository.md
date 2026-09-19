---
paths:
  - "internal/**/repository.go"
  - "internal/**/repository*_test.go"
---

# Repository rules

Loaded when working on a feature's `repository.go` or its tests.

## Project requirement

<!-- ARCHITECT: replace the line below with the invariant of specs §5 that
     every query must satisfy (a tenant filter, an owner filter, a soft-delete
     scope...). Keep it in bold and in one paragraph: probe P09 asks the
     builder to quote it verbatim. Delete this comment when done. -->

**<Requirement that every SQL statement must satisfy, with no exceptions.>**

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

## Operation-specific rules

<!-- ARCHITECT: repository rules that come from the API sections of the specs
     (§6.4 onwards): ordering and tie-breakers, optimistic concurrency,
     delete semantics, and the feature's domain error names. Write
     "Not applicable." if the specs prescribe none. Delete this comment. -->

<Rules from specs §6.4 onwards, one bullet each.>

## Tests

- Real PostgreSQL through the test database helper (plan §5.4); no doubles.
- Every operation affected by an invariant of specs §5 has a repository test
  for it (plan §5.2), and asserts that the other data is unchanged.
