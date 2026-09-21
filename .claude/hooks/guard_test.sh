#!/usr/bin/env bash
# Tests for .claude/hooks/guard.sh. Run it from anywhere:
#   .claude/hooks/guard_test.sh
#
# It builds a throwaway git repository under $TMPDIR, points CLAUDE_PROJECT_DIR
# at it, and pipes one hook payload per case into guard.sh with that case's
# CLAUDE_ROLE and branch. A case asserts only the exit code: 0 = the guard has
# no opinion, 2 = blocked. Nothing in the real repository is touched.

set -uo pipefail

GUARD="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/guard.sh"
[[ -x "$GUARD" ]] || { echo "guard.sh not found or not executable: $GUARD" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required." >&2; exit 1; }

# ------------------------------------------------------------ throwaway repo
REPO="$(mktemp -d "${TMPDIR:-/tmp}/guard_test.XXXXXX")"
trap 'rm -rf "$REPO"' EXIT

git init -q "$REPO"
git -C "$REPO" symbolic-ref HEAD refs/heads/main
git -C "$REPO" config user.email guard@test.local
git -C "$REPO" config user.name "Guard Test"
mkdir -p "$REPO/migrations" "$REPO/docs/reports" "$REPO/.claude/rules"
echo "CREATE TABLE t (id int);" > "$REPO/migrations/000001_init.up.sql"
echo "DROP TABLE t;"           > "$REPO/migrations/000001_init.down.sql"
echo "# specs"                 > "$REPO/docs/project-specs.md"
echo "# plan"                  > "$REPO/docs/sprints-plan.md"
git -C "$REPO" add -A >/dev/null
git -C "$REPO" commit -qm "initial" >/dev/null
git -C "$REPO" switch -q -c sprint/01-test
git -C "$REPO" switch -q main

pass=0
fail=0

# run <name> <expected exit> <role> <branch> <payload>
run() {
  local name="$1" expect="$2" role="$3" branch="$4" payload="$5" out code
  git -C "$REPO" switch -q "$branch" 2>/dev/null ||
    git -C "$REPO" switch -q -c "$branch"
  out="$(printf '%s' "$payload" |
         CLAUDE_PROJECT_DIR="$REPO" CLAUDE_ROLE="$role" "$GUARD" 2>&1 >/dev/null)"
  code=$?
  if [[ "$code" == "$expect" ]]; then
    pass=$((pass + 1))
    printf 'PASS  %s\n' "$name"
  else
    fail=$((fail + 1))
    printf 'FAIL  %s\n      expected exit %s, got %s%s\n' \
      "$name" "$expect" "$code" "${out:+ — $out}"
  fi
}

bash_case() { run "$1" "$2" "$3" "$4" \
  "$(jq -nc --arg c "$5" '{tool_name:"Bash",tool_input:{command:$c}}')"; }

# path_case <name> <expect> <role> <branch> <tool> <field> <path>
path_case() { run "$1" "$2" "$3" "$4" \
  "$(jq -nc --arg t "$5" --arg f "$6" --arg p "$7" \
     '{tool_name:$t,tool_input:{($f):$p}}')"; }

nopath_case() { run "$1" "$2" "$3" "$4" \
  "$(jq -nc --arg t "$5" '{tool_name:$t,tool_input:{}}')"; }

echo "guard.sh: $GUARD"
echo "repo:     $REPO"
echo

echo "--- 1. Data wipes"
bash_case "compose down with -v is blocked"          2 builder sprint/01-test "docker compose down -v"
bash_case "compose down with --volumes is blocked"   2 builder sprint/01-test "docker compose down --volumes"
bash_case "removing a docker volume is blocked"      2 builder sprint/01-test "docker volume rm guard_db"
bash_case "pruning docker volumes is blocked"        2 builder sprint/01-test "docker volume prune -f"
bash_case "the reset target is blocked"              2 builder sprint/01-test "make reset"
bash_case "make -n on it is a dry run, allowed"      0 builder sprint/01-test "make -n reset"
bash_case "make down is allowed"                     0 builder sprint/01-test "make down"
bash_case "a wipe hidden after a safe command is blocked" \
                                                     2 builder sprint/01-test "make check && docker compose down -v"

echo
echo "--- 2. Migrations already on main"
path_case "Edit of a migration on main is blocked"   2 builder sprint/01-test Edit file_path migrations/000001_init.up.sql
path_case "Edit by absolute path is blocked too"     2 builder sprint/01-test Edit file_path "$REPO/migrations/000001_init.up.sql"
path_case "Edit of a new migration is allowed"       0 builder sprint/01-test Edit file_path migrations/000002_users.up.sql
bash_case "rm of a migration on main is blocked"     2 builder sprint/01-test "rm migrations/000001_init.up.sql"
bash_case "sed -i on a migration on main is blocked" 2 builder sprint/01-test "sed -i '' s/int/bigint/ migrations/000001_init.up.sql"
bash_case "reading a migration on main is allowed"   0 builder sprint/01-test "cat migrations/000001_init.up.sql"

echo
echo "--- 3. Commit on main"
bash_case "a role committing on main is blocked"     2 builder main "git commit -m 'sprint 01'"
bash_case "no role committing on main is allowed"    0 ""      main "git commit -m 'config: fix'"
bash_case "a role committing on a sprint branch is allowed" \
                                                     0 builder sprint/01-test "git commit -m 'sprint 01'"

echo
echo "--- 4. Agent configuration, path writes"
path_case "builder Edit of .claude/ is blocked"      2 builder   sprint/01-test Edit  file_path .claude/settings.json
path_case "builder Write of CLAUDE.md is blocked"    2 builder   sprint/01-test Write file_path CLAUDE.md
path_case "auditor Edit of .claude/ is blocked"      2 auditor   sprint/01-test Edit  file_path .claude/hooks/guard.sh
path_case "auditor Edit of CLAUDE.md is blocked"     2 auditor   sprint/01-test Edit  file_path CLAUDE.md
path_case "architect Edit of CLAUDE.md is allowed"   0 architect main           Edit  file_path CLAUDE.md
path_case "architect Write of .claude/rules/ is allowed" \
                                                     0 architect main           Write file_path .claude/rules/repository.md
path_case "architect Edit of .claude/settings.json is blocked" \
                                                     2 architect main           Edit  file_path .claude/settings.json
path_case "architect Edit of a template is blocked"  2 architect main           Edit  file_path .claude/templates/sprints-plan.md
path_case "developer Edit of .claude/ is allowed"    0 ""        main           Edit  file_path .claude/settings.json

echo
echo "--- 5. Agent configuration, Bash"
bash_case "builder rm of a hook is blocked"          2 builder   sprint/01-test "rm .claude/hooks/guard.sh"
bash_case "auditor sed -i of an agent is blocked"    2 auditor   sprint/01-test "sed -i '' s/a/b/ .claude/agents/go-reviewer.md"
bash_case "architect redirect into .claude/ is blocked" \
                                                     2 architect main           "echo x > .claude/settings.json"
bash_case "architect redirect into CLAUDE.md is allowed" \
                                                     0 architect main           "echo x > CLAUDE.md"
bash_case "architect append into .claude/rules/ is allowed" \
                                                     0 architect main           "echo x >> .claude/rules/repository.md"
bash_case "developer rm of a hook is allowed"        0 ""        main           "rm .claude/hooks/guard.sh"
bash_case "reading a hook is allowed for a role"     0 builder   sprint/01-test "cat .claude/hooks/guard.sh"

echo
echo "--- 6. Immutable docs, Bash (every session)"
bash_case "append to the plan is blocked"            2 ""        main "echo x >> docs/sprints-plan.md"
bash_case "sed -i on the specs is blocked"           2 architect main "sed -i '' s/a/b/ docs/project-specs.md"
bash_case "rm of a quoted specs path is blocked"     2 builder   sprint/01-test "rm \"docs/project-specs.md\""
bash_case "a ./-prefixed plan path is blocked"       2 builder   sprint/01-test "rm ./docs/sprints-plan.md"
bash_case "reading the plan is allowed"              0 builder   sprint/01-test "cat docs/sprints-plan.md"
bash_case "a look-alike path outside the repo is allowed" \
                                                     0 ""        main "sed -i '' s/a/b/ /tmp/x/docs/sprints-plan.md.orig"
bash_case "rm of a backup beside a look-alike is allowed" \
                                                     0 ""        main "rm /tmp/x/docs/project-specs.md.bak"

echo
echo "--- 7. The architect writes under docs/ only between sprints"
path_case "architect writes the specs on main"       0 architect main           Write file_path docs/project-specs.md
path_case "architect writes the specs on a sprint branch, blocked" \
                                                     2 architect sprint/01-test Write file_path docs/project-specs.md
path_case "architect edits a report on a sprint branch, blocked" \
                                                     2 architect sprint/01-test Edit  file_path docs/reports/sprint-01.md
path_case "auditor edits a report on a sprint branch" \
                                                     0 auditor   sprint/01-test Edit  file_path docs/reports/sprint-01.md
path_case "architect writing outside docs/ is not this rule" \
                                                     0 architect sprint/01-test Write file_path internal/user/service.go

echo
echo "--- 8. The guard fails closed"
path_case "NotebookEdit into .claude/ is blocked"    2 builder sprint/01-test NotebookEdit notebook_path .claude/notes.ipynb
path_case "NotebookEdit elsewhere is allowed"        0 builder sprint/01-test NotebookEdit notebook_path internal/notes.ipynb
nopath_case "Write with no path is blocked"          2 builder sprint/01-test Write
nopath_case "an unknown write tool with no path is blocked" \
                                                     2 builder sprint/01-test MultiEdit
nopath_case "a payload with no tool name is blocked" 2 builder sprint/01-test ""

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
