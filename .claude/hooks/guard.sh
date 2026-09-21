#!/usr/bin/env bash
# PreToolUse hook (Bash|Edit|Write|NotebookEdit).
# Blocks actions that must never happen, whatever the permission rules say:
#   1. Wiping data: docker compose down -v, docker volume rm/prune, make reset.
#   2. Changing a migration that already exists on main.
#   3. Committing on main (role sessions only).
#   4. Writing the agent configuration itself (role sessions only): CLAUDE.md,
#      .claude/**. Permission deny rules also try to cover this, but their
#      path anchoring is easy to get wrong (a single leading slash resolves
#      relative to the settings FILE, not the project root) -- this hook is
#      the real floor, independent of that.
#      One carve-out: the architect writes CLAUDE.md and .claude/rules/,
#      which are instructions other agents try to follow. It never writes
#      permissions, hooks, launchers, skills or templates, because an agent
#      that can widen its own limits has no limits.
#   5. Writing docs/project-specs.md or docs/sprints-plan.md from the shell,
#      in every session including the developer's: a deliberate change goes
#      through the Edit tool.
#   6. The architect writing anything under docs/ while a sprint/* branch is
#      checked out: the design never moves under a sprint in flight.
#   7. Any tool other than Bash whose path this hook cannot read. Every tool
#      that is not Bash is treated as a path write, with the path taken from
#      .tool_input.file_path or .tool_input.notebook_path; a write-capable
#      tool the guard cannot read is refused, not waved through.
# Exit 0 = no opinion (normal permission flow). Exit 2 = blocked; stderr goes to Claude.
# Regexes avoid \b so they behave the same with GNU and BSD (macOS) grep.

set -uo pipefail

block() {
  echo "Blocked by .claude/hooks/guard.sh: $1" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || block "jq is required by the guard hook. Install jq."

input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
role="${CLAUDE_ROLE:-}"

# The two immutable project documents.
IMMUTABLE_DOCS=(docs/project-specs.md docs/sprints-plan.md)

# True for CLAUDE.md at the project root or anything under .claude/.
# Protected from writes and Bash, but only in role sessions: the plain
# developer session must still be able to fix the configuration by hand.
is_agent_config() {
  [[ "$1" == "CLAUDE.md" || "$1" == ".claude" || "$1" == .claude/* ]]
}

# The part of the agent configuration the architect may write: project
# instructions, never the enforced layer.
is_architect_writable() {
  [[ "$role" == "architect" && ( "$1" == "CLAUDE.md" || "$1" == .claude/rules/* ) ]]
}

# True if the relative path exists on the main branch.
on_main() {
  git -C "$root" cat-file -e "main:$1" 2>/dev/null
}

current_branch() {
  git -C "$root" branch --show-current 2>/dev/null
}

# --------------------------------------------- Path writes (every tool but Bash)
if [[ "$tool" != "Bash" ]]; then
  path="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")"
  if [[ -z "$path" ]]; then
    block "${tool:-this tool} carries no file_path and no notebook_path, so the guard cannot tell what it writes. A write-capable tool the guard cannot read is refused, not waved through."
  fi
  rel="${path#"$root"/}"
  rel="${rel#./}"
  if [[ "$rel" == migrations/* ]] && on_main "$rel"; then
    block "$rel is already on main. Committed migrations are never edited; create a new one with 'make migrate-new name=<description>'."
  fi
  if [[ -n "$role" ]] && is_agent_config "$rel" && ! is_architect_writable "$rel"; then
    block "$rel is the agent configuration. Only a plain 'claude' developer session may change it; the architect may write CLAUDE.md and .claude/rules/ only."
  fi
  if [[ "$role" == "architect" && "$rel" == docs/* ]] && [[ "$(current_branch)" == sprint/* ]]; then
    block "$rel is under docs/ and $(current_branch) is checked out. The architect never changes the design while a sprint is in flight: let the sprint finish, then revise on main."
  fi
  exit 0
fi

cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"

S='[[:space:]]'      # whitespace
E='([[:space:]]|$)'  # end of a word
# Start of a path reference: start of the segment, whitespace, a quote, = or ./
P='(^|[[:space:]"'"'"'=]|\./)'
# End of a path reference: anything that cannot continue a file name.
Q='([^A-Za-z0-9_.-]|$)'

# Each simple command (split on ; & |) is checked on its own, so a dry run or a
# harmless command in one part never excuses a dangerous one in another.
while IFS= read -r seg; do
  seg=" $seg "

  # ----------------------------------------------------------- 1. Data wipes
  if grep -Eq "docker[ -]compose.*${S}down${S}(.*${S})?(-v|--volumes)${E}" <<<"$seg"; then
    block "'docker compose down' with volumes deletes the database. Use 'make down'."
  fi
  if grep -Eq "${S}docker${S}+volume${S}+(rm|prune)${E}" <<<"$seg"; then
    block "removing Docker volumes deletes the database."
  fi
  if grep -Eq "${S}make${S}(.*${S})?reset${E}" <<<"$seg" &&
     ! grep -Eq "${S}make${S}(.*${S})?(-n|--dry-run|--just-print|--recon)${E}" <<<"$seg"; then
    block "'make reset' wipes all data and is reserved for the developer."
  fi

  # ------------------------------------- 2. Agent config (role sessions only)
  mutating="${S}(rm|mv|cp|truncate|tee|touch|ln)${E}|${S}git${S}+(rm|mv)${E}|${S}sed${S}(.*${S})?-i"
  if [[ -n "$role" ]]; then
    for ref in $(grep -Eo '\.claude/[A-Za-z0-9_./-]+|\.claude|CLAUDE\.md' <<<"$seg" | sort -u); do
      is_architect_writable "$ref" && continue
      if grep -Eq "$mutating" <<<"$seg" ||
         grep -Eq ">>?${S}*[^&[:space:]]*${ref//./\\.}" <<<"$seg"; then
        block "$ref is the agent configuration. Only a plain 'claude' developer session may change it."
      fi
    done
  fi

  # ---------------------------------- 3. Immutable docs (every session)
  # Anchored: only a reference that starts a path counts, so an unrelated file
  # such as /tmp/x/docs/sprints-plan.md.orig does not trip this rule.
  for ref in "${IMMUTABLE_DOCS[@]}"; do
    esc="${ref//./\\.}"
    grep -Eq "${P}${esc}${Q}" <<<"$seg" || continue
    if grep -Eq "$mutating" <<<"$seg" ||
       grep -Eq ">>?${S}*[^&[:space:]]*${esc}" <<<"$seg"; then
      block "$ref is immutable. Changes go through the Edit tool, in an architect or developer session."
    fi
  done

  # ------------------------------------------ 4. Migrations already on main
  for ref in $(grep -Eo 'migrations/[A-Za-z0-9_.-]+' <<<"$seg" | sort -u); do
    on_main "$ref" || continue
    if grep -Eq "${S}(rm|mv|cp|truncate|tee)${E}|${S}git${S}+(rm|mv)${E}|${S}sed${S}(.*${S})?-i" <<<"$seg" ||
       grep -Eq ">>?${S}*[^&[:space:]]*${ref//./\\.}" <<<"$seg"; then
      block "$ref is already on main. Committed migrations are never modified, moved or deleted."
    fi
  done

  # ------------------------------------------------ 5. Commit on main
  if [[ -n "$role" ]] && grep -Eq "${S}git${S}(.*${S})?commit${E}" <<<"$seg"; then
    if [[ "$(current_branch)" == "main" ]]; then
      block "you are on main. Create the sprint branch first, in its own command: git switch -c sprint/NN-<slug>."
    fi
  fi
done < <(tr ';&|' '\n\n\n' <<<"$cmd")

exit 0
