---
name: postgres-migrations
description: How to create, write and test a PostgreSQL migration in this project. Use whenever the database schema must change, or a migration file is created or tested.
---

# PostgreSQL migrations

When you apply this skill during a sprint, say so in the report (probe P08).

## Create

- Only with `make migrate-new name=<snake_case_description>`.
  Never create migration files or choose numbers by hand.
- The command creates `migrations/NNNNNN_<name>.up.sql` and
  `migrations/NNNNNN_<name>.down.sql`. Fill both.

## Write

- One logical change per migration.
- The `down` fully reverts the `up`, and nothing else.
- Name constraints and indexes explicitly, following the existing ones:
  `<table>_<columns>_key` for unique constraints and `<table>_<columns>_idx`
  for indexes.
- Allowed values use a `CHECK` constraint, not a PostgreSQL `ENUM` type.
- A new `NOT NULL` column on an existing table needs a `DEFAULT`, so
  existing rows stay valid.
- `down` statements that drop objects use `IF EXISTS`.

## Never

- Edit, move or delete a migration that exists on `main`. The guard hook
  blocks it; the fix is always a new migration.
- Change the schema anywhere other than `migrations/`.

## Test

- Up/down tests use a scratch database created by the test helper (plan
  §5.4), never the shared one (T12).
- Schema tests pin their migrations: migrate the scratch database with an
  `fs.FS` that contains only the migrations under test, so later migrations
  never break them.
- These tests live in `migrations/` as package `migrations_test`, so they
  can import the test helper and the embedded migration files.
- For each new migration, test that `up` produces the expected schema,
  `down` reverts it, and `up` succeeds again.
- The service applies migrations on startup (spec §10.2); tests use the
  same migrate function.
