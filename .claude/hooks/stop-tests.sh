#!/usr/bin/env bash
# Stop hook.
# The builder cannot end its turn while `make test-short` fails.
# Exit 2 = Claude keeps working and receives the failing output.

set -uo pipefail

[[ "${CLAUDE_ROLE:-}" == "builder" ]] || exit 0

input="$(cat)"
# Already continuing because of this hook: let it stop to avoid an endless loop.
[[ "$(jq -r '.stop_hook_active // false' <<<"$input")" == "true" ]] && exit 0

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
# Nothing to test before the module and the Makefile exist (sprint 00 bootstrap).
[[ -f "$root/go.mod" && -f "$root/Makefile" ]] || exit 0

if ! out="$(cd "$root" && make test-short 2>&1)"; then
  {
    echo "stop-tests.sh: 'make test-short' is failing. Fix it before finishing."
    echo "If the failure cannot be fixed within the sprint scope, say so in the report and stop."
    tail -n 30 <<<"$out"
  } >&2
  exit 2
fi

exit 0
