#!/usr/bin/env bash

set -euo pipefail

ROOT="${1:-.}"

if [[ ! -d "$ROOT" ]]; then
  echo "Repository root not found: $ROOT" >&2
  exit 1
fi

print_section() {
  printf '\n## %s\n' "$1"
}

echo "# Runtime Requirement Discovery"
echo "repository_root=$ROOT"

if [[ -f "$ROOT/foundry.toml" ]]; then
  print_section "Foundry RPC Environment Variables"
  rg -o '\$\{[A-Z0-9_]+\}' "$ROOT/foundry.toml" \
    | tr -d '$' \
    | tr -d '{' \
    | tr -d '}' \
    | sort -u || true
fi

print_section "Runtime Environment Variables Referenced In Code"
rg -o 'env(Or|String|Uint|Address|Bool|Bytes32)?\("([A-Z0-9_]+)"' \
  "$ROOT/src" "$ROOT/test" "$ROOT/proposals" \
  --glob '*.sol' \
  2>/dev/null \
  | sed -E 's/.*"([A-Z0-9_]+).*/\1/' \
  | sort -u || true

if [[ -d "$ROOT/docs" ]]; then
  print_section "Environment Variables Mentioned In Docs"
  rg -o 'export [A-Z0-9_]+=' "$ROOT/docs" \
    | sed -E 's/.*export ([A-Z0-9_]+)=/\1/' \
    | sort -u || true
fi
