#!/usr/bin/env bash

set -euo pipefail

BASE_REF="${1:-origin/main}"
COMMIT_WINDOW="${2:-20}"
EXPLICIT_RANGE="${3:-}"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "collect_change_scope.sh must run inside a git repository." >&2
  exit 1
fi

BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"
DIFF_RANGE="${EXPLICIT_RANGE:-${BASE_REF}...HEAD}"

echo "== Branch =="
echo "${BRANCH_NAME}"
echo

echo "== Diff Range =="
echo "${DIFF_RANGE}"
echo

echo "== Recent Commits =="
git log --first-parent --oneline --max-count "${COMMIT_WINDOW}"
echo

echo "== Changed Solidity Files =="
git diff --name-only "${DIFF_RANGE}" -- '*.sol'
echo

echo "== Solidity Diff =="
git diff --unified=3 "${DIFF_RANGE}" -- '*.sol'
