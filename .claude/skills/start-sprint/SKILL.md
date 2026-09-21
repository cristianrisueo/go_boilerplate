---
name: start-sprint
description: Execute sprint NN of docs/sprints-plan.md end to end, or its next fix round after an audit. Builder role only.
argument-hint: "NN"
disable-model-invocation: true
---

# Start sprint $ARGUMENTS

You are the **builder**. `docs/sprints-plan.md` is the approved plan:
do not ask for plan approval. Follow plan §2.3 exactly.

## 0. Decide the mode

- If `CLAUDE_ROLE` is not `builder`, stop and say so.
- If the sprint section is a seeded-defect block (plan §8), stop: it is a
  developer-only protocol.
- If a `sprint/$ARGUMENTS-*` branch exists, its report
  `docs/reports/sprint-$ARGUMENTS.md` exists, and the report's last
  `## Audit — round N` says `CHANGES REQUESTED`, go to **Fix round**.
- Otherwise continue with **New sprint**.

## New sprint

### 1. Preconditions (plan §2.1)

- The working tree is clean and you are on `main`.
- `make test` passes on `main`. Skip this check for sprint `00`: nothing
  exists yet.

If a precondition fails, stop and report it. Do not fix it.

### 2. Branch

Take the branch name from the sprint section. Run these as two separate
commands:

1. `git switch main`
2. `git switch -c sprint/$ARGUMENTS-<slug>`

### 3. Plan

Read, in this order: the sprint section of the plan, plan §2.5–§2.7 and §5,
the spec sections the sprint refers to, and the previous report.

- If the sprint lists **P06**: write down now the context injected at
  session start (role, branch, commits, previous report). It goes in the
  report.
- If the sprint lists **P10**: before writing any code, use the `Explore`
  subagent to map the existing code the sprint touches. Keep its summary.

### 4. Red (T1)

1. Create compiling stubs for every function the tests will call (zero
   values or an explicit "not implemented" error).
2. Write the tests named in the acceptance criteria, in new files only (T2).
3. Run them. They must fail on assertions, not on compilation.
   Keep the relevant output for the report.

If the sprint lists **P07**: right after the red run, end your turn without
fixing anything. The `Stop` hook must block you and return the failures.
Record what happened, then continue. If you are not blocked, the developer
will tell you to continue, and the probe is `FAIL`.

### 5. Green

Write the minimum code that makes the tests pass, inside the sprint scope.

- For any schema change, apply the `postgres-migrations` skill.
- If the sprint lists **P09**: when you work on a `repository.go`, note the
  rule file that was loaded and quote its project requirement verbatim.
- If a criterion cannot be met within scope, stop implementing and go to
  step 8 with the reason under "Open issues".

### 6. Verify

1. Run the sprint's verification section, step by step, exactly as written.
2. Run `make check`, `make test-short` and `make test` (Definition of Done).
3. From the plan's coverage sprint on (plan §2.6), run the sprint's coverage
   command.

Everything must pass. Keep every command and its result.

### 7. Probes (plan §6)

Run each probe listed for this sprint exactly once, exactly as written.
If a probe that must be blocked is not blocked: run its fallback at once,
record `FAIL`, write the report and commit (steps 8–9), then stop. The
sprint is halted until the developer fixes the configuration.

### 8. Report

Write `docs/reports/sprint-$ARGUMENTS.md` with the Edit or Write
tool, not a Bash heredoc: guard.sh scans Bash command text for dangerous
patterns and can flag documentation that merely quotes one (for example,
a probe's expected command inside a table cell). Follow section 1 of
`.claude/templates/sprint-report.md`: same headings, same order, same
spelling. Replace every placeholder.

- Coverage: before the plan's first coverage sprint, write the "Not
  required" line of the template.
- Probes: one row per probe of the sprint, or `None.`
- Deviations and Open issues: `None.` unless something differs from the
  plan; then say what and why.

### 9. Commit

1. `git add -A`
2. `git commit -m "sprint $ARGUMENTS: <summary>"`

Then stop and tell the developer:
"Sprint $ARGUMENTS is ready for `/audit-sprint $ARGUMENTS`."
Never merge or push.

## Fix round

1. Read the last `## Audit — round N` section of the report.
2. If the report already has a `## Fix round` section, stop: the sprint has
   had its one fix round (plan §2.5) and the developer decides.
3. Address **every blocking finding**. Fix non-blocking findings only if the
   change is trivial and inside the scope. Existing tests stay untouched
   (T2).
4. Re-run steps 6 and 7.
5. Append a `## Fix round N` section to the end of the report, following
   section 3 of `.claude/templates/sprint-report.md`. Never rewrite earlier
   sections.
6. `git add -A`, then `git commit -m "sprint $ARGUMENTS: fix round N"`.
7. Stop and ask the developer to re-run `/audit-sprint $ARGUMENTS`.
