#!/usr/bin/env bash
# Starts a Claude Code session with the auditor role.
# Usage: .claude/bin/audit.sh   then run /audit-sprint NN
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

branch="$(git branch --show-current)"
if [[ "$branch" != sprint/* ]]; then
  echo "auditor.sh: checkout the sprint branch first (current: ${branch:-detached})" >&2
  exit 1
fi

export CLAUDE_ROLE=auditor

exec claude \
  --settings "$root/.claude/roles/auditor.json" \
  --permission-mode dontAsk \
  "$@"
