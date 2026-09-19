#!/usr/bin/env bash
# PostToolUse hook (Edit|Write).
# After a .go file is written: format it with gofmt and run go vet on its package.
# PostToolUse cannot undo the edit. On failure it exits 2 so Claude sees the
# problem and fixes it in its next step.

set -uo pipefail

report() {
  echo "go-format.sh: $1" >&2
  exit 2
}

input="$(cat)"
path="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Only existing Go files, and only once the module exists (sprint 00 bootstrap).
[[ "$path" == *.go && -f "$path" && -f "$root/go.mod" ]] || exit 0
command -v go >/dev/null 2>&1 || report "go is not installed; cannot check $path."

rel="${path#"$root"/}"

if ! out="$(gofmt -w "$path" 2>&1)"; then
  report "gofmt could not parse $rel:
$out"
fi

pkg="./$(dirname "$rel")"
if ! out="$(cd "$root" && go vet "$pkg" 2>&1)"; then
  report "go vet failed for package $pkg after editing $rel:
$(tail -n 30 <<<"$out")"
fi

exit 0
