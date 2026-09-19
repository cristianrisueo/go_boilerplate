#!/usr/bin/env bash
# Starts a Claude Code session with the builder role.
# Usage: .claude/bin/builder.sh   then run /start-sprint NN
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

export CLAUDE_ROLE=builder

exec claude \
  --settings "$root/.claude/roles/builder.json" \
  --permission-mode acceptEdits \
  "$@"
