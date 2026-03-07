# Audit Preparation
## Scope Snapshot

- Repository: `moonwell-contracts-v2`
- PR head: `e3579d4832b20162e52f94579b794c30be7dc244`
- Review focus: final `MIP-X43` oracle rollout semantics after the deploy-fix commits

## SDL Summary Metrics

- Changed Solidity files: 2
- Confirmed threats: 4
- Release-blocking findings: 1
- Commands executed: 9
- Passing targeted commands: 7
- Failing targeted commands: 1
- Blocked or timed-out targeted commands: 1

## Recommended Audit Focus

- Oracle denomination lineage for changed config rows
- Canonical repo oracle compositions that the PR bypasses
- Validation helpers that assert wiring but not semantics
- Semantic regression tests for correlated assets and wrapped-asset feeds

## Accepted Risks

- None accepted. TM-101 is release-blocking.

## False-Positive Disposition

- TM-101 stayed a candidate until the rerun compared the final PR config, the repository's canonical `cbETH_ORACLE` construction, and live Base outputs through the deterministic semantic helper.
- TM-102 and TM-103 were confirmed after inspecting `mipx43.validate` and the smoke integration assertion at `price > 0`.
- TM-104 was confirmed after inventorying the Foundry invariant directory and finding only `xWELL` coverage.

## Diff-To-Test Closure

- Proposal execution: covered and passing.
- Expected-versus-observed semantic safety: covered and failing the hard gate.
- Narrow wrapper fuzz coverage: present but only partial for the changed semantic risk.
- Broad smoke integration: advisory only.
- Invariant coverage: open and blocked.

## Semantic Validation Summary

- The final PR head keeps Base `cbETH` wired to `cbETHETH_ORACLE`.
- The repository already defines `cbETH_ORACLE` as `ETH_ORACLE * cbETHETH_ORACLE` for Base.
- `ChainlinkOracle.getUnderlyingPrice()` and `getPrice()` do not compose a ratio feed into USD; they fetch the selected feed and rescale by decimals.
- `check_oracle_semantics.sh` turned that mismatch into a deterministic failure with a measured drift of about `99.95%` relative to the canonical path.

## Runtime Fallback Summary

- Runtime discovery succeeded before Stage 3.
- Base RPC input came from local `.env`, while public Optimism and Moonbeam endpoints were sufficient for the proposal harness.
- Runtime setup was no longer the dominant issue in this rerun; semantic correctness was.
- PDF export succeeded and produced `sdl-output/diff-sdl/final-report.pdf` as a `19` page artifact.

## Open Questions

- Which other changed oracle rows depend on canonical compositions that are not encoded directly in `ChainlinkOracleConfigs`?
- Should semantic oracle checks live in the repository, the skill, or both?
- Should proposal validation assert coarse price sanity for correlated assets before any rollout can pass?

## Pre-Audit Actions

1. Restore Base `cbETH` to the canonical USD-composed `cbETH_ORACLE` path.
2. Add an expected-versus-observed regression test for Base `cbETH`.
3. Add one proposal or oracle invariant for denomination correctness.
4. Promote semantic oracle-lineage checks into the repository's native test harness.
