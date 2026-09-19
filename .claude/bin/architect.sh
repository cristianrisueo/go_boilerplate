#!/usr/bin/env bash
# Starts a Claude Code session with the architect role.
# Usage: .claude/bin/architect.sh   then run /design-project
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

export CLAUDE_ROLE=architect

exec claude \
  --settings "$root/.claude/roles/architect.json" \
  "$@"
