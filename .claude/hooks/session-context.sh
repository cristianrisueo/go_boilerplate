#!/usr/bin/env bash
# SessionStart hook (startup, resume, clear, compact).
# Everything printed to stdout is added to Claude's context, so each session
# starts knowing its role, the branch, recent commits and the latest sprint report.

set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$root" || exit 0

echo "## Session context (from .claude/hooks/session-context.sh)"
echo "Role: ${CLAUDE_ROLE:-developer (no role launcher)}"

if git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Branch: $(git branch --show-current 2>/dev/null || echo detached)"
  if [[ -z "${CLAUDE_ROLE:-}" && "$(git branch --show-current 2>/dev/null)" == sprint/* ]]; then
    echo "WARNING: no role set on a sprint branch."
    echo "If you meant to implement or audit, exit and relaunch with"
    echo ".claude/bin/implement.sh or .claude/bin/audit.sh."
  fi
  if git rev-parse HEAD >/dev/null 2>&1; then
    echo
    echo "### Latest commits"
    git log --oneline -5
  fi
fi

latest="$(ls docs/sprints/reports/sprint-*.md 2>/dev/null | sort | tail -n 1)"
echo
if [[ -z "$latest" ]]; then
  echo "### Latest sprint report"
  echo "None yet. No sprint has been completed."
  exit 0
fi

echo "### Latest sprint report: $latest (key sections; read the file for the rest)"
# Summary, Deviations and Open issues in full, plus every audit verdict line.
awk '
  /^## /       { show = ($0 ~ /^## (Summary|Deviations|Open issues)/) }
  /^\*\*Verdict:\*\*/ { print "Audit " $0; next }
  show         { print }
' "$latest"

exit 0
