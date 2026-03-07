# Risk Register
## Scope

This register covers Moonwell PR #578 final head `e3579d4832b20162e52f94579b794c30be7dc244` across the diff range `85b7a7d70730e8a7aa0255b80acbfd997c211c22..e3579d4832b20162e52f94579b794c30be7dc244`.

## Severity Model

- Impact: `Critical`, `High`, `Medium`, `Low`
- Likelihood: `High`, `Medium`, `Low`
- Priority:
  - `P0`: direct solvency or economic-integrity failure
  - `P1`: release-blocking validation or configuration failure
  - `P2`: major coverage or review-gap finding
  - `P3`: low-severity hygiene issue

## Risk Table

| Risk ID | Summary | Impact | Likelihood | Priority | Response | First-Pass Verdict | Second-Pass Verdict | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TM-101 | Base `cbETH` is priced from raw `cbETH/ETH` instead of a USD-composed feed, so `getUnderlyingPrice` would surface a value about `1977.55x` too low relative to the canonical path. | Critical | High | P0 | Reduce | Candidate | Confirmed | `ChainlinkOracleConfigs.sol:41-43`, `Configs.sol:278-285`, semantic helper output |
| TM-102 | Proposal validation proves pointer wiring, not denomination correctness, so a semantically wrong feed can pass validation. | High | High | P1 | Reduce | Candidate | Confirmed | `mip-x43.sol:343-430` |
| TM-103 | Smoke-style oracle integration checks `price > 0` only, so plausible-but-wrong prices can still pass review if the suite completes. | Medium | High | P2 | Reduce | Candidate | Confirmed | `ChainlinkOEVWrapperIntegration.t.sol:322-328`, timeout result |
| TM-104 | No invariant suite protects proposal-driven oracle semantics for the changed surface. | Medium | Medium | P2 | Reduce | Confirmed | Confirmed | `test/invariant/xWELLInvariant.t.sol:17-120`, invariant inventory search |

## Mitigations

- TM-101:
  - map Base `cbETH` to the canonical USD-composed `cbETH_ORACLE`, not `cbETHETH_ORACLE`
  - add a semantic regression test that compares changed oracle rows against existing canonical repo compositions
- TM-102:
  - extend proposal validation with denomination-lineage assertions
  - assert that correlated assets such as `cbETH` and `ETH` stay in the same rough USD order of magnitude
- TM-103:
  - replace pure non-zero checks with expected-versus-observed price assertions
  - keep broad smoke suites as advisory when they only prove liveness or time out
- TM-104:
  - add at least one proposal or oracle invariant that encodes denomination correctness on changed surfaces

## Residual Risks

- Similar ratio-versus-USD mistakes can recur anywhere config rows bypass existing composite-oracle helpers.
- Reviewers can still over-trust passing proposal harnesses unless semantic checks are mandatory and automated.
- Public RPC variability still affects reproducibility for multichain proposal verification.

## Recommended Next Actions

1. Treat TM-101 as a release blocker.
2. Replace the Base `cbETH` row with the canonical composed USD path.
3. Extend `mipx43.validate` or adjacent tests to assert expected price meaning rather than only wrapper wiring.
4. Add one invariant for proposal-driven oracle semantics before treating `diff-sdl` as complete for this surface.
