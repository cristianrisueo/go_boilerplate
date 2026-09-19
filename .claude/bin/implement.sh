#!/usr/bin/env bash
# Starts a Claude Code session with the implementer role.
# Usage: .claude/bin/implement.sh   then run /start-sprint NN
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
cd "$root"

export CLAUDE_ROLE=implementer

exec claude \
  --settings "$root/.claude/roles/implementer.json" \
  --permission-mode acceptEdits \
  "$@"
