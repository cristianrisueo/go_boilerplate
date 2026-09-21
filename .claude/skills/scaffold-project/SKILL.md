---
name: scaffold-project
description: Generate docs/sprints-plan.md, docs/sprints-debt.md, docs/reports/, the "Project rules" of CLAUDE.md and .claude/rules/repository.md from docs/project-specs.md. Architect role only.
---

# Scaffold project

You are the **architect**. `docs/project-specs.md` is the input — written by
`/design-project` or by hand, in a chat, against
`.claude/templates/project-specs.md`. Everything downstream is your output:
the sprint plan, the debt ledger, the reports directory, the "Project rules"
of `CLAUDE.md` and `.claude/rules/repository.md`.

You never write `docs/project-specs.md`, in any step. If the specs are wrong,
you say so and stop; fixing them is `/design-project`'s job or the
developer's.

You work without pauses. Report at the end, not in between.

## 0. Check where you are

- If `CLAUDE_ROLE` is not `architect`, stop and say so.
- If a `sprint/*` branch is checked out, stop. A sprint is in flight, and
  regenerating the plan under it is how an audit ends up judging code against
  a document that moved.
- The working tree may be dirty **only** in `docs/project-specs.md`: the
  specs may have just been pasted in or revised. Anything else uncommitted,
  stop and say what it is.

## 1. Intake check

Read `.claude/templates/project-specs.md` and `docs/project-specs.md`, and
verify:

| Check                                                                       |
| --------------------------------------------------------------------------- |
| `docs/project-specs.md` exists                                              |
| Every section of the template is present, with the same numbering           |
| No section marked REQUIRED says "Not applicable."                           |
| §5 uses the numbered `I1…In` format of the template                         |
| §6.3 is a table of error codes                                              |
| No `<placeholder>` is left anywhere                                         |

If anything fails, list **every** failure with the section it is in, and
stop. Generate nothing: a plan derived from incomplete specs is worse than no
plan, because it looks executable.

## 2. Find the boundary

1. List `docs/reports/`. The highest `sprint-NN.md` is the last executed
   sprint: **it and every sprint before it are closed**. On a first run
   nothing is closed.
2. If anything is closed, read those reports, with their deviations and open
   issues, and read the current `docs/sprints-plan.md`.

## 3. Write the plan

Write `docs/sprints-plan.md` from its template. Sections 1–4 are the process:
copy them, replacing only placeholders. Then:

- **§5 Test plan.** Adapt T1–T14 to this project. Name the test database
  helper and, in §5.4, the packages that exist only to support tests: T6
  excludes them from the coverage signal.
- **§5.2 and §5.3.** One row per operation affected by an invariant, one row
  per error code.
- **§6 Probes.** Keep the catalogue as it is; fill the sprint column and the
  first migration's name.
- **§7–§8 Sprints.** Derive them from the specs:
  - **Small.** One sprint delivers one coherent slice: an endpoint with its
    tests, a schema change, the skeleton. If a sprint's scope needs more
    than a handful of bullets, split it.
  - Every acceptance criterion is verifiable by a machine: a named test or a
    command with an expected result. Never "the code is clean" or "it works
    well". A criterion you cannot verify that way is a defect of the plan.
  - Every sprint exercises at least one piece of the configuration.
  - Sprint 00 is the skeleton. Include two seeded-defect sprints, the first
    right after the first sprint that ships real domain logic. End with a
    hardening sprint that clears `docs/sprints-debt.md`.

On a re-run, the plan grows at the end, like migrations:

| You may                            | You may not                                 |
| ---------------------------------- | ------------------------------------------- |
| Rewrite pending sprints            | Touch the section of a closed sprint        |
| Add new sprints at the end         | Renumber closed sprints                     |
|                                    | Change an acceptance criterion already verified |

Work already merged is never fixed by rewriting the past: **add a sprint that
refactors it**.

## 4. Derive the project-specific configuration

Regenerated on every run.

1. **`CLAUDE.md`, "Project rules".** One rule per invariant of specs §5,
   stated so a reviewer can check it against a diff, plus the import rules
   of specs §8.2 and how database tests get their pool. Delete the
   instruction comment.
2. **`.claude/rules/repository.md`.** The "Project requirement" in bold, one
   paragraph, quotable verbatim (probe P09 asks for it); and the
   operation-specific rules from specs §6.4 onwards. Delete the comments.
3. **A new file under `.claude/rules/`** only if a part of the codebase has
   its own conventions and getting them wrong is expensive. Two rules with
   no reader are worse than one that is read.

You may not write anything else under `.claude/`. Permissions, hooks,
launchers, skills and templates are the enforced layer: an agent that can
widen its own limits has none.

## 5. Prepare the workspace

- `docs/reports/.gitkeep`, if it does not exist.
- `docs/sprints-debt.md` from `.claude/templates/sprints-debt.md`, header and
  empty table — **only if it does not exist**. An existing ledger is never
  overwritten: it holds findings the hardening sprint still has to clear.

The auditor may edit these files but not create them, so leaving them out
would halt the first audit.

## 6. Check what you wrote

Before reporting, verify the documents against each other and fix what is
mechanical. Where a gap needs a decision, leave it and report it.

| Check                                                            | Fix or report                                     |
| ---------------------------------------------------------------- | ------------------------------------------------- |
| Every invariant of specs §5 has a row in plan §5.2               | Report: it needs a test at two levels             |
| Every error code of specs §6.3 has a row in plan §5.3            | Report: it needs a test that provokes it          |
| Every probe of plan §6 has a sprint                              | Fix                                               |
| Every acceptance criterion names a test or a command             | Fix, or report if the criterion is not verifiable |
| Every test the plan's §5.3 names is named by some acceptance criterion | Fix                                          |
| Every file of the specs §9 tree is created by some sprint        | Report                                            |
| No sprint depends on something no earlier sprint builds          | Report: the order is wrong                        |
| Every section of both templates exists, with no placeholder left | Fix                                               |

## 7. Report and stop

In this order:

1. The files you wrote or changed.
2. Every decision you made on the developer's behalf, so they can review it.
3. The gaps from step 6 you did not fix, and what each one needs.
4. Read `.claude/roles/builder.json` and list only the commands the plan
   needs that it does not allow (code generators, linters, migration tools),
   as a block the developer can paste. **Do not edit that file.**
5. The next step: commit everything on `main`, then `/start-sprint` for the
   first pending sprint.

Never commit: the initial commit is the developer's (plan §1.2).
