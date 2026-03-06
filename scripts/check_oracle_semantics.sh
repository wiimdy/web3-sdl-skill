#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage:
  check_oracle_semantics.sh \
    --rpc-url <url> \
    [--address-book <json>] \
    --asset <name-or-address> \
    --selected-feed <name-or-address> \
    --expected-feed <name-or-address> \
    [--consumer <name-or-address>] \
    [--market <name-or-address>] \
    [--consumer-signature 'getUnderlyingPrice(address)(uint256)'] \
    [--max-relative-drift 0.05]

This helper compares a changed oracle path against the expected or canonical path.
It exits with code 2 when --max-relative-drift is set and the selected feed
diverges from the expected feed beyond that threshold.
EOF
  exit 1
}

ADDRESS_BOOK=""
RPC_URL=""
ASSET_REF=""
SELECTED_FEED_REF=""
EXPECTED_FEED_REF=""
CONSUMER_REF=""
MARKET_REF=""
CONSUMER_SIGNATURE="getUnderlyingPrice(address)(uint256)"
MAX_RELATIVE_DRIFT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --address-book)
      ADDRESS_BOOK="${2:-}"
      shift 2
      ;;
    --rpc-url)
      RPC_URL="${2:-}"
      shift 2
      ;;
    --asset)
      ASSET_REF="${2:-}"
      shift 2
      ;;
    --selected-feed)
      SELECTED_FEED_REF="${2:-}"
      shift 2
      ;;
    --expected-feed)
      EXPECTED_FEED_REF="${2:-}"
      shift 2
      ;;
    --consumer)
      CONSUMER_REF="${2:-}"
      shift 2
      ;;
    --market)
      MARKET_REF="${2:-}"
      shift 2
      ;;
    --consumer-signature)
      CONSUMER_SIGNATURE="${2:-}"
      shift 2
      ;;
    --max-relative-drift)
      MAX_RELATIVE_DRIFT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

if [[ -z "${RPC_URL}" || -z "${ASSET_REF}" || -z "${SELECTED_FEED_REF}" || -z "${EXPECTED_FEED_REF}" ]]; then
  usage
fi

if [[ -n "${CONSUMER_REF}" && -z "${MARKET_REF}" ]]; then
  echo "--market is required when --consumer is set." >&2
  exit 1
fi

for cmd in cast python3; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Missing required dependency: ${cmd}" >&2
    exit 1
  fi
done

is_address() {
  [[ "$1" =~ ^0x[a-fA-F0-9]{40}$ ]]
}

resolve_ref() {
  local ref="$1"

  if is_address "${ref}"; then
    printf '%s\n' "${ref}"
    return 0
  fi

  if [[ -z "${ADDRESS_BOOK}" ]]; then
    echo "Cannot resolve named reference without --address-book: ${ref}" >&2
    exit 1
  fi

  python3 - "${ADDRESS_BOOK}" "${ref}" <<'PY'
import json
import sys

path, needle = sys.argv[1], sys.argv[2]
with open(path, "r", encoding="utf-8") as handle:
    data = json.load(handle)

for entry in data:
    if entry.get("name") == needle:
        print(entry["addr"])
        sys.exit(0)

print(f"Name not found in address book: {needle}", file=sys.stderr)
sys.exit(1)
PY
}

latest_round_answer() {
  local address="$1"
  FOUNDRY_DISABLE_NIGHTLY_WARNING="${FOUNDRY_DISABLE_NIGHTLY_WARNING:-1}" \
    cast call "${address}" 'latestRoundData()(uint80,int256,uint256,uint256,uint80)' --rpc-url "${RPC_URL}" \
    | awk 'NR==2 {print $1; exit}'
}

decimals_of() {
  local address="$1"
  FOUNDRY_DISABLE_NIGHTLY_WARNING="${FOUNDRY_DISABLE_NIGHTLY_WARNING:-1}" \
    cast call "${address}" 'decimals()(uint8)' --rpc-url "${RPC_URL}" \
    | awk 'NR==1 {print $1; exit}'
}

consumer_value() {
  local consumer="$1"
  local market="$2"
  FOUNDRY_DISABLE_NIGHTLY_WARNING="${FOUNDRY_DISABLE_NIGHTLY_WARNING:-1}" \
    cast call "${consumer}" "${CONSUMER_SIGNATURE}" "${market}" --rpc-url "${RPC_URL}" \
    | awk 'NR==1 {print $1; exit}'
}

ASSET_ADDRESS="$(resolve_ref "${ASSET_REF}")"
SELECTED_FEED_ADDRESS="$(resolve_ref "${SELECTED_FEED_REF}")"
EXPECTED_FEED_ADDRESS="$(resolve_ref "${EXPECTED_FEED_REF}")"
CONSUMER_ADDRESS=""
MARKET_ADDRESS=""

if [[ -n "${CONSUMER_REF}" ]]; then
  CONSUMER_ADDRESS="$(resolve_ref "${CONSUMER_REF}")"
  MARKET_ADDRESS="$(resolve_ref "${MARKET_REF}")"
fi

ASSET_DECIMALS="$(decimals_of "${ASSET_ADDRESS}")"
SELECTED_ANSWER_RAW="$(latest_round_answer "${SELECTED_FEED_ADDRESS}")"
SELECTED_DECIMALS="$(decimals_of "${SELECTED_FEED_ADDRESS}")"
EXPECTED_ANSWER_RAW="$(latest_round_answer "${EXPECTED_FEED_ADDRESS}")"
EXPECTED_DECIMALS="$(decimals_of "${EXPECTED_FEED_ADDRESS}")"
CONSUMER_ANSWER_RAW=""

if [[ -n "${CONSUMER_ADDRESS}" ]]; then
  CONSUMER_ANSWER_RAW="$(consumer_value "${CONSUMER_ADDRESS}" "${MARKET_ADDRESS}")"
fi

python3 - \
  "${ASSET_REF}" \
  "${ASSET_ADDRESS}" \
  "${ASSET_DECIMALS}" \
  "${SELECTED_FEED_REF}" \
  "${SELECTED_FEED_ADDRESS}" \
  "${SELECTED_ANSWER_RAW}" \
  "${SELECTED_DECIMALS}" \
  "${EXPECTED_FEED_REF}" \
  "${EXPECTED_FEED_ADDRESS}" \
  "${EXPECTED_ANSWER_RAW}" \
  "${EXPECTED_DECIMALS}" \
  "${CONSUMER_REF}" \
  "${CONSUMER_ADDRESS}" \
  "${MARKET_REF}" \
  "${MARKET_ADDRESS}" \
  "${CONSUMER_ANSWER_RAW}" \
  "${MAX_RELATIVE_DRIFT}" <<'PY'
from __future__ import annotations

from decimal import Decimal, getcontext
import sys

getcontext().prec = 50

(
    asset_ref,
    asset_address,
    asset_decimals,
    selected_ref,
    selected_address,
    selected_answer_raw,
    selected_decimals,
    expected_ref,
    expected_address,
    expected_answer_raw,
    expected_decimals,
    consumer_ref,
    consumer_address,
    market_ref,
    market_address,
    consumer_answer_raw,
    max_relative_drift,
) = sys.argv[1:]


def scale_to_1e18(answer_raw: str, decimals_raw: str) -> Decimal:
    answer = Decimal(answer_raw)
    decimals = int(decimals_raw)
    if decimals == 18:
      return answer
    if decimals < 18:
      return answer * (Decimal(10) ** (18 - decimals))
    return answer / (Decimal(10) ** (decimals - 18))


selected_scaled = scale_to_1e18(selected_answer_raw, selected_decimals)
expected_scaled = scale_to_1e18(expected_answer_raw, expected_decimals)

ratio = Decimal(0)
if selected_scaled != 0:
    ratio = expected_scaled / selected_scaled

relative_drift = Decimal(0)
if expected_scaled != 0:
    relative_drift = abs(selected_scaled - expected_scaled) / abs(expected_scaled)

status = "ok"
exit_code = 0
if max_relative_drift:
    threshold = Decimal(max_relative_drift)
    if relative_drift > threshold:
        status = "drift_exceeded"
        exit_code = 2

print("oracle_semantic_check")
print(f"status={status}")
print(f"asset_ref={asset_ref}")
print(f"asset_address={asset_address}")
print(f"asset_decimals={asset_decimals}")
print(f"selected_feed_ref={selected_ref}")
print(f"selected_feed_address={selected_address}")
print(f"selected_answer_raw={selected_answer_raw}")
print(f"selected_feed_decimals={selected_decimals}")
print(f"selected_answer_1e18={selected_scaled}")
print(f"expected_feed_ref={expected_ref}")
print(f"expected_feed_address={expected_address}")
print(f"expected_answer_raw={expected_answer_raw}")
print(f"expected_feed_decimals={expected_decimals}")
print(f"expected_answer_1e18={expected_scaled}")
print(f"expected_over_selected_ratio={ratio}")
print(f"relative_drift={relative_drift}")

if consumer_ref:
    print(f"consumer_ref={consumer_ref}")
    print(f"consumer_address={consumer_address}")
    print(f"market_ref={market_ref}")
    print(f"market_address={market_address}")
    print(f"consumer_answer_raw={consumer_answer_raw}")

sys.exit(exit_code)
PY
