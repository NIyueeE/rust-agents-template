#!/usr/bin/env bash
# Self-test for githooks/check-docs: a clean clone passes, a broken mirror fails.
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

git clone --quiet --no-hardlinks "$root" "$tmp/repo"
cd "$tmp/repo"

githooks/check-docs >/dev/null

# Remove the second level-2 heading from the Chinese checks page: the mirror
# must no longer have the same heading structure as its English counterpart.
awk '/^## / { n++; if (n == 2) next } { print }' docs/checks.zh.md > "$tmp/checks.zh.md"
mv "$tmp/checks.zh.md" docs/checks.zh.md

if githooks/check-docs >/dev/null 2>&1; then
  echo "check-docs self-test failed: a broken mirror was accepted" >&2
  exit 1
fi

echo "check-docs self-test passed"
