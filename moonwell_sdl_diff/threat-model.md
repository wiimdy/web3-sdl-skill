# Threat Model
## Scope

- Repository: `moonwell-contracts-v2`
- Mode: `diff-sdl`
- Review date: `2026-03-07`
- Commit range: `85b7a7d70730e8a7aa0255b80acbfd997c211c22..e3579d4832b20162e52f94579b794c30be7dc244`
- Changed Solidity files:
  - `proposals/ChainlinkOracleConfigs.sol`
  - `proposals/mips/mip-x43/mip-x43.sol`
- Primary changed surfaces:
  - Base and Optimism oracle config rows in `ChainlinkOracleConfigs`
  - `mipx43` deploy, build, and validate flow
  - feed-to-wrapper wiring for `CHAINLINK_ORACLE`

## Assets And Security Objectives

- Governance proposal execution must complete without introducing semantically invalid oracle wiring.
- `CHAINLINK_ORACLE` must return USD-denominated prices for collateral and borrow markets.
- Base `cbETH` must preserve the repository's canonical USD composition rather than regress to a raw ratio feed.
- Validation and test coverage must detect semantic pricing regressions instead of only catching reverts or zero prices.

## Trust Boundaries

- Proposal code trusts chain-specific addresses loaded from `chains/*.json`.
- `mipx43` trusts each configured oracle name to match the denomination expected by downstream consumers.
- `ChainlinkOracle` trusts `getFeed(symbol)` to return a feed that already represents the correct unit.
- Review automation only proves denomination safety when it adds an expected-versus-observed semantic check.

## Actors And Roles

- `TEMPORAL_GOVERNOR`: owns wrapper configuration and governance rollout state.
- `CHAINLINK_ORACLE`: serves market prices to mTokens and inherits any denomination mistake in the configured feed.
- Proposal deployer or harness runner: executes `mipx43` in multi-fork tests.
- External oracle contracts: Chainlink USD feeds, ratio feeds, and composite feeds referenced by the address book.
- Borrowers and liquidators: indirectly affected when a market price is wired in the wrong unit.

## Entry Points

- `ChainlinkOracleConfigs.constructor`
- `mipx43.run`
- `mipx43.deploy`
- `mipx43.build`
- `mipx43.validate`
- `mipx43._validateFeedsPointToWrappers`
- `mipx43._validateCoreWrappersConstructor`
- `ChainlinkOracle.getUnderlyingPrice`
- `ChainlinkOracle.getPrice`

## External Dependencies

- Base address-book entries in `chains/8453.json`
- repository canonical oracle construction in `proposals/Configs.sol:278-285`
- `ChainlinkOracle` consumer behavior in `src/oracles/ChainlinkOracle.sol:58-110`
- proposal validation helpers in `proposals/mips/mip-x43/mip-x43.sol:343-430`
- smoke integration in `test/integration/oracle/ChainlinkOEVWrapperIntegration.t.sol:322-328`
- runtime RPC inputs for Base, Optimism, and Moonbeam

## Threat Inventory

| Threat ID | Summary | Status | Evidence |
| --- | --- | --- | --- |
| TM-101 | Base `cbETH` is wired to `cbETHETH_ORACLE`, a raw `cbETH / ETH` ratio feed, even though `ChainlinkOracle` consumers expect a USD-denominated path. | Confirmed | `proposals/ChainlinkOracleConfigs.sol:41-43`, `proposals/Configs.sol:278-285`, `src/oracles/ChainlinkOracle.sol:58-110`, semantic helper output |
| TM-102 | Proposal validation confirms pointer wiring and wrapper constructor state, but it never checks denomination lineage or expected quote currency. | Confirmed | `proposals/mips/mip-x43/mip-x43.sol:343-430` |
| TM-103 | The repo's smoke-style oracle integration only asserts `price > 0`, so a plausible-but-wrong price can still pass review if the suite finishes. | Confirmed | `test/integration/oracle/ChainlinkOEVWrapperIntegration.t.sol:322-328` |
| TM-104 | No invariant suite covers proposal-driven oracle semantics for the changed surface. | Confirmed | `test/invariant/xWELLInvariant.t.sol:17-120`, invariant inventory search under `test/` |

## STRIDE-Web3 Notes

- Spoofing: low direct relevance in this diff.
- Tampering: highest relevance because one config row changes what unit a market trusts.
- Repudiation: medium because validation can produce a false sense of safety while omitting semantic checks.
- Information Disclosure: low.
- Denial of Service: low for the final PR head because the proposal harness now executes successfully.
- Elevation of Privilege: low direct change, but governance still has the ability to push a semantically invalid feed across markets.

## Evidence Appendix

- `forge build` passed in the fresh `iteration-3` checkout.
- `forge test --match-contract LiveProposalsIntegrationTest --match-test testExecutingInDevelopmentProposals -vv` passed with runtime envs set.
- `forge test --match-path test/unit/ChainlinkOEVWrapperUnit.t.sol --match-test testFuzz_GetCollateralTokenPrice_NoRevert -vv` passed.
- `check_oracle_semantics.sh` exited `2` with `status=drift_exceeded`.
- `selected_answer_raw=1124650193922520000`
- `expected_answer_raw=2224051595339541204057`
- `expected_over_selected_ratio=1977.5496481999999999995874272707127936217070774362`
- `timeout 120 forge test --match-contract ChainlinkOEVWrapperIntegrationTest -vv` exited `124`, so the broad wrapper smoke path stayed advisory.
