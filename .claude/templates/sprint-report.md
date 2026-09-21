# Sprint report template

Single source for the format of `docs/reports/sprint-NN.md`
(plan §2.6 and §4.3). Used by `/start-sprint` and `/audit-sprint`.

Headings must be copied **exactly**: `.claude/hooks/session-context.sh`
reads `## Summary`, `## Deviations`, `## Open issues` and `**Verdict:**`.
Replace every `<placeholder>`; never leave one in a report.

## 1. Initial report (written by `/start-sprint`)

````markdown
# Sprint NN — <title>

## Summary

<What was built, in three to five lines.>

## Files

- `<path>` — <created | modified>: <one line>

## Tests first

### Red

```text
<relevant excerpt of the failing run>
```

### Green

```text
<passing run>
```

## Acceptance criteria

| ID | Verified by | Result |
|---|---|---|
| SNN-AC01 | `<TestName>` or Verification step N | PASS |

## Verification

```text
$ <command of step 1>
<full result>
```

Step 1: PASS · Step 2: PASS

## Coverage

<Per-package coverage output, with the sprint's feature packages called
out, or: Not required before sprint <coverage sprint>.>

## Probes

| ID | Action | Expected | Observed | PASS/FAIL |
|---|---|---|---|---|
| Pxx | <action> | <expected> | <observed> | PASS |

<Or: None.>

## Deviations

None.

## Open issues

None.
````

`Deviations` and `Open issues`: `None.` is the expected value. Anything else
states what and why. Every `Open issues` entry pastes in the output it rests
on — the failing command and its result, the error, the log line. An entry
with no output is a rumour, and the next round cannot check it.

## 2. Audit round (appended by `/audit-sprint`)

````markdown
## Audit — round N

**Verdict:** APPROVED | CHANGES REQUESTED

| # | Severity | Check | Location | Finding |
|---|---|---|---|---|
| 1 | blocking | A6 | <path>:<line> | <finding> |

A1 PASS · A2 PASS · A3 PASS · A4 PASS · A5 PASS · A6 PASS · A7 PASS · A8 PASS · A9 PASS · A10 PASS
````

- Write only one of the two verdict values.
- With no findings, write `No findings.` instead of the table.
- Use `N/A` for checks that do not apply (seeded-defect audit: A9, A10).
- `N` is 1 or 2. Round 1 is the full audit; round 2 has the closed scope of
  plan §4.3. There is no round 3.
- On a halted sprint, add: `Sprint halted (plan §2.5): developer decision required.`

## 3. Fix round (appended by `/start-sprint`)

````markdown
## Fix round N

| Finding | Change | Evidence |
|---|---|---|
| <audit round>.<#> | <what changed> | `<TestName>` or command |

### Verification

```text
$ <command>
<full result>
```

### Deferred

<Every amendment this round defers, written out verbatim, or: None.>
````

An amendment the sprint defers is written out **verbatim** in the fix-round
section that defers it: not summarised, and not left as a reference to a
finding number. Whoever picks it up later — the hardening sprint, the next
audit, the developer — must be able to act on it without reading the audit
again.

## 4. Correcting an earlier section

Never rewrite earlier sections: audit rounds and fix rounds are only
appended. A statement a later round proves false is the one exception, and
it is struck through **in place**, with a pointer to the round that corrects
it:

```markdown
~~Every acceptance criterion passes.~~ (False; corrected in Audit — round 2:
SNN-AC03 has no test that asserts it.)
```

The history stays, the falsehood does not. Nothing is deleted, and no earlier
sentence is quietly reworded into being right.
