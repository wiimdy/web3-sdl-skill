# Runtime Validation

Use this reference whenever the SDL run benefits from fork-based or RPC-backed
checks. This restores the tiered runtime contract from the earlier monolithic
skill.

## Runtime Input Gate

Discover runtime inputs from repository files before treating them as unknown.

Start with:

- `foundry.toml`
- repository docs
- `.env.example`
- proposal or test harness code

Use `./scripts/discover_runtime_requirements.sh .` to collect the first pass.

Request runtime inputs only when the run needs Tier 1 or Tier 2 checks and the
repository does not already declare the required RPC or env names.

Collect:

- target chain
- RPC URL or env var name
- optional fork block

If the user cannot supply runtime inputs, continue with Tier 3 only and record
explicit `SKIP` entries for the higher tiers.

## Harness Selection

Prefer the repository's native test harness when it encodes fork setup,
cross-chain ordering, or proposal bootstrapping assumptions.

For example:

- use `forge test` proposal harnesses when proposal code relies on fixed fork
  IDs or env-managed primary forks
- use direct `forge script` only when that path is known to preserve those
  assumptions

If a direct script path fails because fork IDs or bootstrap invariants drift,
record that as a harness mismatch rather than a protocol finding.

## Tiered Validation Policy

Use three tiers:

- Tier 1: RPC-required dynamic runtime checks
- Tier 2: optional fork or integration-context checks
- Tier 3: RPC-free semantic checks

Tier 3 remains mandatory even when Tier 1 or Tier 2 cannot run.

For `diff-sdl`, Tier 3 alone is not enough when the changed surface materially
depends on runtime execution. Report a blocker if the required integration path
cannot run after reasonable environment discovery.

## Tier 3 Minimum Checks

Run these static or RPC-free checks when the changed surface warrants them:

- oracle name and key-pattern checks
- config-key denomination inference
- oracle semantic trace consistency
- validator reverse-gap checks
- Slither blind-spot review

## Runtime Reporting

Record in `test-verification.md`:

- requested runtime inputs
- discovered runtime inputs and where they were found
- provided chain and RPC details
- fork block
- skipped tiers and reasons
- evidence produced by each tier

## Example

**Example 1:**
Input: The changed code alters a price-consumer path and fork checks are useful.
Output: Try Tier 1 or Tier 2 if RPC details exist, otherwise run Tier 3 semantic
checks and mark Tier 1 or Tier 2 as `SKIP` with the missing input.
