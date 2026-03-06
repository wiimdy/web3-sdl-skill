# Semantic Validation

Use this reference whenever changed code touches external integrations, oracles,
config keys, validators, proposals, or any path where the protocol's intended
meaning can diverge from the implementation.

## Grounding Rules

Anchor threat identification to recent commit evidence and matching Solidity
diffs in `diff-sdl`.

Trace every new or changed external touchpoint back to:

- the commit history
- the changed file and function
- the relevant diff hunk
- the downstream verification target

Do not infer changed external touchpoints from untouched historical code.

## Severity Evidence Rules

Support every `High` or `Critical` claim with concrete evidence from:

- code pointers
- diff hunks
- tests
- runtime behavior
- corroborated analysis outputs

Use these statuses when triaging:

- `Candidate`
- `Confirmed`
- `Rejected`
- `Needs-Info`

Do not escalate a `High` or `Critical` issue from Slither or similar static
output alone.

## Oracle Semantic Correctness

Treat oracle semantic correctness as a mandatory threat class for
oracle-integrated protocols.

For each changed oracle or price-related touchpoint, record:

- expected unit or invariant
- observed unit or semantics
- required conversion path
- mismatch hypothesis

Validate:

- denomination alignment
- base or quote orientation
- decimals and scale
- wrapper versus feed semantics

Build a denomination lineage for each changed price path:

`asset -> selected feed -> quote currency -> required composition -> consumer assumption`

Do not stop at "price is non-zero" or "the address was wired correctly". Those
checks only prove liveness, not correctness.

When the repository exposes live addresses and RPC access, prefer a deterministic
comparison command such as:

```bash
./scripts/check_oracle_semantics.sh \
  --address-book chains/8453.json \
  --asset cbETH \
  --selected-feed cbETHETH_ORACLE \
  --expected-feed cbETH_ORACLE \
  --consumer CHAINLINK_ORACLE \
  --market MOONWELL_cbETH \
  --rpc-url "$BASE_RPC_URL" \
  --max-relative-drift 0.05
```

Treat an exit code of `2` from this helper as evidence that the selected feed
materially diverges from the expected semantic path.

## Expected-Versus-Observed Semantic Checks

Design at least one check that compares the observed result against the result
that should follow from the protocol's own logic.

Use checks such as:

- expected composed price versus observed direct-feed price
- expected quote currency versus observed quote currency
- expected order of magnitude versus observed order of magnitude
- expected relationship to a correlated asset versus observed relationship

These checks matter because many real failures produce plausible, non-zero
outputs that are still economically wrong.

When possible, make the expected-versus-observed check deterministic:

- compare the changed feed to the canonical feed with `check_oracle_semantics.sh`
- enforce a maximum relative drift for the changed surface
- capture the helper output in `test-verification.md`

## Canonical Pattern Comparison

Search the repository for the existing canonical way to represent the same
asset, feed family, or semantic transformation.

Compare the changed path against:

- existing config builders
- existing composite-oracle constructions
- prior proposal patterns
- existing validation helpers

If the repository already has a canonical USD construction for an asset and the
diff swaps in a raw ratio feed, treat that mismatch as a high-priority signal.

## Correlated-Asset Sanity Checks

When the changed surface prices an LSD, wrapped asset, staked asset, or
exchange-rate asset, compare its USD output to a correlated anchor asset.

Examples:

- `cbETH`, `wstETH`, `rETH`, `weETH` should be in the same order of magnitude
  as `ETH` in USD terms
- share-price or exchange-rate assets should only be used directly when the
  downstream consumer expects a ratio rather than a USD price

Treat a large semantic divergence as a likely pricing flaw even if the feed
returns a valid positive number.

## Wrapper And Feed Interface Compatibility

Check constructor and runtime assumptions before accepting a new wrapper or
proxy target.

When a wrapper assumes methods such as `latestRound()`, `latestRoundData()`,
`getRoundData()`, `decimals()`, `description()`, or `version()`, verify that
the configured feed actually supports that interface. Treat composite or
exchange-rate adapters as a separate semantic class until that compatibility is
proven.

## Config Semantic Trace

Trace changed config keys by meaning, not just by address existence.

Build this chain:

`config key -> address or feed -> consumer function -> assumed denomination or semantic`

Capture unknowns explicitly instead of guessing.

## Name-Derived Address Collision Checks

When deployment keys, wrapper names, proxy identifiers, or address-book labels
are derived from config strings, check whether two changed config entries expand
to the same derived name.

Record:

- source config entries
- derived key or name
- whether the loop deprecates, overwrites, or reuses an earlier deployment
- whether the collision is intentional and safely handled

This matters because duplicate names can silently replace fresh deployments even
when the underlying oracle address is identical.

## Validator Reverse-Gap Analysis

For each changed validator or proposal function such as `validate*`, record:

- what the function validates
- what it does not validate
- which threat IDs those gaps relate to

## Output Expectations

Reflect the semantic-validation results in:

- `threat-model.md`
- `change-threat-analysis.md` when running `diff-sdl`
- `test-verification.md`
- `audit-preparation.md`

## Example

**Example 1:**
Input: A changed config key now points to a different oracle wrapper.
Output: Trace the wrapper to its consumer path, check denomination and scale,
record any mismatch hypothesis, and map the result into both the threat model
and the verification plan.

**Example 2:**
Input: A proposal deploys wrappers by appending `_OEV_WRAPPER` to each
`oracleName`.
Output: Expand the changed config rows, detect duplicate derived names such as
two assets sharing one oracle key, and determine whether the deployment loop
reuses or corrupts wrapper state.

**Example 3:**
Input: A proposal maps `cbETH` to a `cbETH/ETH` feed while the consumer expects
USD prices.
Output: Compare the observed feed semantics against the repository's canonical
USD composition with `check_oracle_semantics.sh`, show that the result is a
ratio rather than a USD price, and escalate the mismatch even if the price is
positive and the proposal validates.
