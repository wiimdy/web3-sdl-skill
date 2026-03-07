# Change Threat Analysis
## Scope

- Repository: `moonwell-contracts-v2`
- Reviewed PR head: `e3579d4832b20162e52f94579b794c30be7dc244`
- Explicit diff range: `85b7a7d70730e8a7aa0255b80acbfd997c211c22..e3579d4832b20162e52f94579b794c30be7dc244`
- Goal: determine whether the final PR state both executes and preserves correct oracle semantics

## Commit Timeline

- `0898069b` `Add MIP-X43: Activate OEV wrappers for all remaining markets`
- `318d6781` `Exclude composite oracles, fix duplicate oracle deploy`
- `8c6175ac` `Fix duplicate wrapper deploy for shared oracles, remove unused import, fix int256 validation`
- `cd663dd1` `Implement updates to existing OEV wrapper fees, changing the split from 60/40 to 70/30 for MIP-X38 wrappers on Base and Optimism`
- `d533baf5` `Change OEV fee split to 70/30 protocol/liquidator`
- `fb4c8c64` `update addresses`
- `e3579d48` `add proposal id`

The later commits removed the earlier deploy blocker, which made this rerun about semantic correctness rather than executability alone.

## Diff Summary

- `proposals/ChainlinkOracleConfigs.sol`
  - modifies Base and Optimism oracle rollout rows
  - keeps Base `cbETH` configured as `OracleConfig("cbETHETH_ORACLE", "cbETH", "MOONWELL_cbETH")`
  - comments out composite paths that previously reverted on deployment
- `proposals/mips/mip-x43/mip-x43.sol`
  - adds the deploy, wire, and validate flow for the expanded wrapper rollout
  - validates configured feeds and wrapper state but not oracle denomination meaning
- Diff stats on the in-scope Solidity files:
  - `proposals/ChainlinkOracleConfigs.sol`: `146` changed lines in the reviewed range
  - `proposals/mips/mip-x43/mip-x43.sol`: `701` added lines in the reviewed range

## Changed Functions

- `ChainlinkOracleConfigs.constructor`
- `mipx43.run`
- `mipx43.deploy`
- `mipx43.build`
- `mipx43.validate`
- `mipx43._validateFeedsPointToWrappers`
- `mipx43._validateCoreWrappersConstructor`

## New Or Changed Trust Assumptions

- The final PR assumes a raw ratio feed can substitute for the repository's canonical USD-composed path.
- The final PR assumes proposal validation is sufficient if the wrapper points at the intended address and has a non-zero cached round id.
- The final PR assumes a non-zero market price is enough evidence of oracle correctness.
- The review runtime assumes Base, Optimism, and Moonbeam RPC access is present because the proposal harness creates and selects multiple forks.

## STRIDE-Web3 Findings

| Threat ID | STRIDE-Web3 class | Finding | Evidence |
| --- | --- | --- | --- |
| TM-101 | Tampering / economic integrity failure | Base `cbETH` is configured with `cbETHETH_ORACLE` even though the repository's own canonical path composes `ETH_ORACLE * cbETHETH_ORACLE` for USD consumers. | `proposals/ChainlinkOracleConfigs.sol:41-43`, `proposals/Configs.sol:278-285`, `src/oracles/ChainlinkOracle.sol:58-110` |
| TM-102 | Repudiation / tampering | `_validateFeedsPointToWrappers` and `_validateCoreWrappersConstructor` prove address wiring and constructor state, but they do not prove denomination correctness. | `proposals/mips/mip-x43/mip-x43.sol:343-430` |
| TM-103 | Repudiation / defense gap | `testAllChainlinkOraclesAreSet` only checks that `oracle.getUnderlyingPrice(...) > 0`, so it cannot distinguish a ratio-space answer from a USD-space answer. | `test/integration/oracle/ChainlinkOEVWrapperIntegration.t.sol:322-328` |
| TM-104 | Denial of assurance | No relevant invariant suite exists for proposal-driven oracle semantic regressions. | `test/invariant/xWELLInvariant.t.sol:17-120` |

## Verification Targets

- Proposal execution with runtime envs set:
  - `forge test --match-contract LiveProposalsIntegrationTest --match-test testExecutingInDevelopmentProposals -vv`
- Narrow fuzz evidence on the changed wrapper surface:
  - `forge test --match-path test/unit/ChainlinkOEVWrapperUnit.t.sol --match-test testFuzz_GetCollateralTokenPrice_NoRevert -vv`
- Semantic onchain comparison:
  - `check_oracle_semantics.sh --asset cbETH --selected-feed cbETHETH_ORACLE --expected-feed cbETH_ORACLE --consumer CHAINLINK_ORACLE --market MOONWELL_cbETH`
- Review-gap check:
  - `timeout 120 forge test --match-contract ChainlinkOEVWrapperIntegrationTest -vv`

## Open Questions

- Are there any other ratio or composite feeds in the changed config rows that bypass an existing canonical USD composition?
- Should the address book or config naming convention distinguish ratio feeds from USD feeds more explicitly?
- Should the repository add a native Foundry semantic oracle regression test rather than relying on an external helper?
