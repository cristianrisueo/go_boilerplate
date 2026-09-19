---
name: design-project
description: Write the project documents from the templates, or revise the pending part of an existing design. Architect role only.
disable-model-invocation: true
---

# Design project

You are the **architect**. You produce the two documents the whole workflow
depends on, and nothing else: no service code, no tests.

## 0. Decide the mode

- If `CLAUDE_ROLE` is not `architect`, stop and say so.
- If `docs/project-specs.md` and `docs/sprints-plan.md` both exist, go to
  **Revision**.
- Otherwise continue with **New project**.

## New project

### 1. Read

1. `.claude/templates/project-specs.md` and
   `.claude/templates/sprints-plan.md`: the sections, their numbering and
   the instruction comments. Both are fixed; never drop or renumber a
   section.
2. `CLAUDE.md`: the conventions the project inherits.
3. If the repository already has Go code, use the `Explore` subagent to map
   it before proposing anything: packages, layers, how requests reach the
   database, what tests exist. Keep its summary; the specs describe what is
   there, not an ideal that contradicts it.

### 2. Ask

Work through the open decisions **one at a time**, in this order, with a
recommendation and its reason for each. Wait for the answer before moving on.

1. What the service does, and what is explicitly out of scope.
2. The domain model: entities, fields, validation.
3. The invariants (specs §5): rules that admit no exception. These matter
   most: `go-reviewer`, the audit and the "Project rules" of `CLAUDE.md` all
   derive from them.
4. The API: response format, operations, error catalogue.
5. The stack, as a closed list of dependencies.
6. Architecture: layout, allowed imports, where components are wired.
7. Test infrastructure: how database tests get their pool and isolate data.

Never ask about something the templates already fix (the Makefile targets,
the probe catalogue, the audit protocol). Prefer a concrete proposal the
developer can correct over an open question.

### 3. Write the specs

Write `docs/project-specs.md` from its template: every section, same
numbering, `Not applicable.` where a section does not apply, no
`<placeholder>` left. Fill the decision log (§14) with the choices of step 2
and their reason.

Stop and let the developer read it before continuing.

### 4. Write the plan

Write `docs/sprints-plan.md` from its template. Sections 1–4 are the process:
copy them, replacing only placeholders. Then:

- **§5** Test plan: adapt T1–T14 to this project; name the test database
  helper and the packages that exist only to support tests (§5.4).
- **§6** Probes: keep the catalogue as it is; fill the sprint column and the
  first migration's name.
- **§7–§8** Sprints: derive them from the specs. Every sprint gets machine-
  verifiable acceptance criteria — a named test or a command with an expected
  result — and exercises at least one piece of the configuration. Sprint 00
  is the skeleton; include two seeded-defect sprints and end with a hardening
  sprint, as §7 explains.

Stop and let the developer read it before continuing.

### 5. Derive the project-specific configuration

Only after the developer approves both documents:

1. `CLAUDE.md`, section "Project rules": one rule per invariant of specs §5,
   stated so that a reviewer can check it against a diff, plus the import
   rules of specs §8.2 and how database tests get their pool. Delete the
   instruction comment.
2. `.claude/rules/repository.md`: the "Project requirement" in bold, one
   paragraph, quotable verbatim (probe P09 asks for it); and the
   operation-specific rules from specs §6.4 onwards. Delete the comments.
3. A new file under `.claude/rules/` only if a part of the codebase has its
   own conventions and getting them wrong is expensive. Two rules with no
   reader are worse than one that is read.

You may not write anything else under `.claude/`. Permissions, hooks,
launchers, skills and templates are the enforced layer: an agent that can
widen its own limits has none.

### 6. Prepare the workspace

Create what the other roles need to exist before their first run:

- `docs/reports/.gitkeep`
- `docs/sprints-debt.md` from `.claude/templates/sprints-debt.md`, with the
  header and an empty table.

The auditor may edit these files but not create them, so leaving them out
would halt the first audit.

### 7. Report and stop

Tell the developer, in this order:

1. The files you wrote.
2. Every decision they left to you, so they can review it.
3. Any command the sprints need that `.claude/roles/builder.json` does not
   allow (code generators, linters, migration tools), as a block they can
   paste. **Do not edit that file.**
4. The next step: commit everything on `main`, then run `/start-sprint 00`.

Never commit: the initial commit is the developer's (plan §1.2).

## Revision

Invoked again on a project already under way, to redesign what has not been
built yet. The line is what has already been executed.

### 1. Find the boundary

1. List `docs/reports/`. The highest `sprint-NN.md` is the last executed
   sprint: **everything up to and including it is closed**.
2. Read those reports, and the deviations and open issues they record.
3. Read the current specs and plan.
4. Check `git status`: if a `sprint/*` branch is checked out or the tree is
   dirty, stop. A sprint is in flight and redesigning under it is how an
   audit ends up judging code against a document that moved.

### 2. Ask what changes and why

One decision at a time, as in step 2 above. Say plainly which already-built
behaviour the change invalidates.

### 3. Apply it

| You may                                                          | You may not                                            |
| ---------------------------------------------------------------- | ------------------------------------------------------ |
| Edit the specs, recording every change in the decision log (§14) | Edit the section of a sprint that already has a report |
| Rewrite pending sprints                                          | Renumber executed sprints                              |
| Add new sprints at the end                                       | Change acceptance criteria already verified            |
| Update the "Project rules" and `.claude/rules/`                  | Touch anything else under `.claude/`                   |

Work already merged is never fixed by rewriting the past: **add a sprint that
refactors it**. The plan grows at the end, like migrations.

### 4. Report and stop

State which sprints you changed, which you left untouched and why, what the
decision log now records, and what the developer should re-read before the
next `/start-sprint`. Never commit.
