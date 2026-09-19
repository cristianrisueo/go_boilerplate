---
name: audit-sprint
description: Audit sprint NN against docs/sprints/plan.md §4 and persist the verdict in its report. Auditor role only.
argument-hint: "NN"
disable-model-invocation: true
---

# Audit sprint $ARGUMENTS

You are the **auditor**. You did not write this code. You never modify code
or tests and never fix anything: you find, classify and report.
**Do not trust the report.** Re-run everything yourself (plan §4.1).

## 0. Preconditions

- `CLAUDE_ROLE` is `auditor` and the current branch is `sprint/$ARGUMENTS-*`.
- `docs/sprints/reports/sprint-$ARGUMENTS.md` exists.
- The working tree is clean, except the report itself when it is untracked
  (seeded-defect audit). Anything else means the builder may still be
  working: stop and say so.
- Round `N` = number of `## Audit — round` sections in the report, plus 1.

**Seeded-defect mode.** If the report says "Seeded-defect audit", there is
no builder report to check. In this mode, A1 uses the standard command
below, A9 and A10 are `N/A`, and A8 is judged against the spec only.

## 1. Read

The sprint section of the plan; plan §2.7, §3, §4 and §5; the spec sections
the sprint touches; the report; and the full diff: `git diff main...HEAD`.

## 2. Checks, in order (plan §4.2)

| # | What to do |
|---|---|
| A1 | Re-run the sprint's verification section step by step. If the sprint has none, run `make check && make test-short && make test`. In every case also run `make check`, `make test-short` and `make test`. |
| A2 | `git diff --name-status main...HEAD -- '*_test.go'` shows only `A`. In the diff, look for new `t.Skip` outside the test database helper (plan §5.4) and for weakened assertions. |
| A3 | For every criterion ID, open the test or command that verifies it and confirm it asserts exactly that criterion. A test that exists but does not assert it does not count. |
| A4 | Check the rules of plan §5 (T1–T14) that apply to this sprint. From the plan's coverage sprint (plan §2.6), run the coverage command; below 80 %, list the uncovered functions (blocking only if a criterion needs them, T6). |
| A5 | Status codes, error codes, envelope, validation and ordering in the diff match the spec. |
| A6 | Every invariant of spec §5 holds in the diff (see also the "Project rules" of `CLAUDE.md`). |
| A7 | Use the `go-reviewer` subagent on `git diff main...HEAD`. Include its findings. |
| A8 | No file and no behaviour outside the sprint scope (plan §2.7). New test file names beyond spec §9 are expected. |
| A9 | Every probe of the sprint is in the report and marked `PASS`. |
| A10 | The report has every section of plan §2.6. |

## 3. Classify (plan §4.3)

- **blocking**: any failed check, any spec deviation, any `go-reviewer`
  finding about correctness, invariants, error handling or context
  propagation.
- **non-blocking**: naming, comments, style beyond `gofmt` and `go vet`.

The verdict is `CHANGES REQUESTED` only if there is at least one blocking
finding. If this is round 3 and the verdict is `CHANGES REQUESTED`, the sprint is
halted: add the line the template gives for that case.

## 4. Persist

Append an `## Audit — round N` section to the end of the report, following
section 2 of `docs/templates/sprint-report.md` exactly. The
`SessionStart` hook reads its `**Verdict:**` line.

## 4b. Record non-blocking debt

For every non-blocking finding of this round that calls for a change to the
code, append one row to the table in `docs/sprints/debt.md`: sprint number,
location, a one-line finding, status `Open`. Skip a finding when the audit
itself justifies the current behaviour, or when it belongs to another list
(a weak metric, a plan defect, a naming choice the plan prescribes). Skip
this step entirely if no finding qualifies.

## 5. Commit the report and the ledger

Include `docs/sprints/debt.md` in both commands only if step 4b touched it.

1. `git add docs/sprints/reports/sprint-$ARGUMENTS.md docs/sprints/debt.md`
2. `git commit -m "sprint $ARGUMENTS: audit round N" -- docs/sprints/reports/sprint-$ARGUMENTS.md docs/sprints/debt.md`

Then show the verdict and the findings table to the developer.
Never merge.
