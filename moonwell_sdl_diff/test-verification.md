# Test Verification
## Scope

- Mode: `diff-sdl`
- PR head: `e3579d4832b20162e52f94579b794c30be7dc244`
- Diff range: `85b7a7d70730e8a7aa0255b80acbfd997c211c22..e3579d4832b20162e52f94579b794c30be7dc244`
- Focus: proposal execution, changed oracle semantics, validation blind spots, and changed-surface coverage

## Commands Run

| Command | Result | Notes |
| --- | --- | --- |
| `./scripts/collect_change_scope.sh 85b7a7d7 50 '85b7a7d7..e3579d4832b20162e52f94579b794c30be7dc244'` | Pass | Narrowed the review to the full PR evolution ending at the final head. |
| `./scripts/discover_runtime_requirements.sh .` | Pass | Surfaced required RPC env vars and `PRIMARY_FORK_ID`. |
| `forge build` | Pass | Fresh `iteration-3` checkout compiled successfully. |
| `forge test --match-contract LiveProposalsIntegrationTest --match-test testExecutingInDevelopmentProposals -vv` | Pass | Proposal execution succeeded with `.env`-backed Base RPC and public Optimism or Moonbeam RPCs. |
| `forge test --match-path test/unit/ChainlinkOEVWrapperUnit.t.sol --match-test testFuzz_GetCollateralTokenPrice_NoRevert -vv` | Pass | Narrow wrapper fuzz path still executes, but it is not a semantic oracle proof by itself. |
| `./scripts/check_oracle_semantics.sh --address-book chains/8453.json --asset cbETH --selected-feed cbETHETH_ORACLE --expected-feed cbETH_ORACLE --consumer CHAINLINK_ORACLE --market MOONWELL_cbETH --rpc-url \"$BASE_RPC_URL\" --max-relative-drift 0.05` | Fail | Exited `2` with `status=drift_exceeded`; canonical path was about `1977.55x` larger than the selected feed path. |
| `timeout 120 forge test --match-contract ChainlinkOEVWrapperIntegrationTest -vv` | Timeout | Broad wrapper integration remained too slow for a hard gate and still only enforces liveness on the relevant smoke path. |
| `rg -n \"invariant|Invariant\" test` | Pass | Inventory search showed only `xWELL` invariants for local Foundry coverage; none target the changed oracle or proposal surface. |
| `./scripts/render_final_report.sh final-report.md final-report.pdf` | Pass | Produced a `19` page PDF artifact at `sdl-output/diff-sdl/final-report.pdf`. |

## Threat-To-Test Mapping

| Threat ID | Surface | Integration | Fuzz | Invariant | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| TM-101 | `ChainlinkOracleConfigs` Base `cbETH` row vs `ChainlinkOracle` semantics | `LiveProposalsIntegrationTest::testExecutingInDevelopmentProposals` passed, proving the proposal executes | `testFuzz_GetCollateralTokenPrice_NoRevert` passed, but does not assert denomination correctness | None | Confirmed | `check_oracle_semantics.sh` failed with `drift_exceeded`; ratio feed `1.12465019392252e18` vs canonical path `2.224051595339541204057e21` |
| TM-102 | `mipx43.validate` semantic blind spot | Validation helpers executed inside the proposal harness | None | None | Confirmed | `mip-x43.sol:343-430` checks pointers and wrapper state only |
| TM-103 | Smoke-style oracle integration weakness | `ChainlinkOEVWrapperIntegrationTest` timed out; relevant smoke assertion only requires `price > 0` | None | None | Confirmed review gap | `ChainlinkOEVWrapperIntegration.t.sol:322-328`, timeout `124` |
| TM-104 | Proposal or oracle invariant coverage | None | None | No relevant suite found | Blocked | Only `test/invariant/xWELLInvariant.t.sol` was present for local Foundry invariants |

## Added Or Modified Tests

- No repository tests were modified during this evaluation run.
- The rerun identifies three missing test additions:
  - an expected-versus-observed regression test for Base `cbETH`
  - a proposal-validation assertion for denomination lineage
  - a changed-surface invariant that constrains correlated-asset price meaning

## Results

- Build succeeded.
- The native proposal harness succeeded, which proves the final PR head is executable.
- The semantic helper independently identified a critical denomination mismatch on Base `cbETH`.
- Narrow wrapper fuzz coverage exists but does not close the semantic gap.
- Broad wrapper smoke coverage remained advisory because it timed out and only checks liveness on the relevant path.

## Failures And Their Meaning

- A passing proposal harness does not prove semantic correctness.
- A non-zero oracle price does not prove the price is denominated in the right unit.
- The most decisive signal came from expected-versus-observed semantic comparison, not from no-revert behavior.
- The missing invariant coverage is a real blocker for strict changed-surface closure, not a harmless skip.

## Blockers

- No relevant invariant suite exists for the changed proposal or oracle surface.
