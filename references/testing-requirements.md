# Testing Requirements

Treat testing as a delivery gate, not a documentation afterthought. Tests turn
threat claims into evidence and make the final report useful for later audits.

## Core Rule

Run real verification commands before claiming completion.

Minimum build-and-test flow for Foundry projects:

```bash
forge build
forge test
```

Discover runtime requirements before declaring a blocker:

```bash
./scripts/discover_runtime_requirements.sh .
```

For changed oracle or config semantics, prefer a targeted semantic comparison
before relying on a broad smoke suite:

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

Add targeted commands when the repository already separates suites, for example:

- integration tests for multi-contract flows
- fuzz tests for input ranges and ordering
- invariant tests for accounting and authorization properties

## Threat-to-Test Mapping

Maintain a mapping for each non-trivial threat or changed risk surface:

- threat ID
- affected contracts/functions
- integration test coverage
- fuzz coverage
- invariant coverage
- execution result

Keep this mapping explicit because it connects the written report to executable
checks.

Build a diff-to-test matrix before execution:

- map each changed state-modifying function to at least one test and linked
  threat IDs
- map each changed oracle or config touchpoint to at least one semantic check
- map each changed validator or proposal function to at least one reverse-gap
  check
- record explicit exceptions when coverage cannot be added

For changed oracle, pricing, config, or accounting surfaces, include at least
one expected-versus-observed test. The test should fail when the system returns
a logically wrong but non-zero result.

If a broad integration suite times out or only checks liveness, keep it as
advisory coverage and use a targeted semantic helper or narrower integration
path as the hard gate.

## Threat-To-Test Template

ALWAYS use this table shape when you summarize verification coverage:

| Threat ID | Surface | Integration | Fuzz | Invariant | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| TM-001 | `Vault.deposit()` | `testDepositFlow` | `testFuzzDepositBounds` | `invariantTotalAssets` | Pass | `test/Vault.t.sol` |

## Diff SDL Hard Gate

Run all three categories in `diff-sdl`:

- integration tests
- fuzzing
- invariant tests

Stop and report the exact blocker when any category cannot run:

- missing RPC
- missing env vars such as `PRIMARY_FORK_ID`
- missing fixtures
- broken build
- unsupported test harness
- external dependency outage

Separate an environment blocker from a code defect. Once the required runtime
inputs are supplied, rerun the same command so the report can say whether the
surface is truly broken or only misconfigured.

## Scope-Accurate Coverage

Do not count an unrelated suite as satisfying the `diff-sdl` hard gate.

Examples:

- a repository-wide invariant suite does not satisfy a changed proposal or
  oracle diff unless it actually executes that surface
- a unit fuzz test on a reusable wrapper does not satisfy governance proposal
  execution by itself

Mark these cases as partial coverage and keep the changed surface open until the
targeted suite runs or a blocker is recorded.

## Trail Of Bits Verification Stack

Use the verification tools from `tob-tooling.md`:

- `property-based-testing` to design or add fuzz and invariant coverage
- `spec-to-code-compliance` to compare implementation behavior with the stated
  design or security assumptions
- `static-analysis` as an advisory signal when available

## Outcome-Based Validation

Use outcome-based validation when changed code can affect value, risk,
accounting, or configuration semantics.

Cover these families when the surface warrants them:

- result-value invariant checks
- economic behavior scenario checks
- validator negative tests
- pre or post diff differential result checks

## Semantic Expectation Tests

Design semantic expectation tests when the changed surface can return a valid
looking but wrong result.

Prefer assertions such as:

- "price matches expected composition"
- "output quote currency matches consumer assumption"
- "result stays within an expected ratio band relative to anchor assets"
- "changed config produces the same semantic class as the prior canonical path"

Do not accept tests that only prove:

- no revert
- non-zero output
- address equality
- event emission

Those are useful smoke checks, but they are not semantic correctness checks.

## Oracle And Config Test Design

For changed oracle or config paths, add or run tests that cover:

- feed denomination lineage
- expected composed result versus observed configured result
- correlated-asset sanity ranges
- downstream consumer behavior under the configured feed

If the repository already contains a canonical oracle construction for the same
asset, add a comparison test against that canonical path whenever feasible.
Prefer `check_oracle_semantics.sh` when the repository exposes an address book
and live RPC access because it produces deterministic drift evidence.

## Multichain Proposal Repositories

Prefer repository-native proposal or integration tests when:

- proposals create or select multiple forks
- fork IDs are assumed to be stable integers
- env vars determine the primary fork or runtime wiring

Use direct `forge script` execution only when the repository demonstrates that
the script path is stable. Otherwise, treat the script path as advisory and rely
on the proposal harness for the hard gate.

## Coverage Gates

Use repository or config-defined coverage gates when they exist. The earlier
monolithic SDL defaulted to:

- line coverage >= 90%
- branch coverage >= 80%
- function coverage = 100%

## Static-Analysis Confidence

Treat static-analysis results as advisory unless local evidence corroborates
them. Do not use Slither alone to justify a `High` or `Critical` classification.

## Project SDL Expectations

Focus `project-sdl` verification on the highest-risk flows:

- critical external integrations
- privileged operations
- accounting or solvency invariants
- upgrade or configuration paths

Report a high-risk flow as an SDL gap and add the test when feasible. This
keeps the baseline honest about what the repository still cannot prove.

## Reporting Requirements

Record:

- commands executed
- suites added or modified
- threat-to-test coverage
- failures and what they imply
- blockers that prevented completion

## Example

**Example 1:**
Input: TM-004 covers a new withdrawal path with accounting risk.
Output: Add one integration test, one fuzz test, and one invariant that each
exercise that path, then record the exact command and result.

**Example 2:**
Input: A proposal repository has `xWELL` invariants, but the diff changes an
oracle-wrapping governance proposal.
Output: Record the `xWELL` invariants as unrelated coverage, run the proposal
integration path plus targeted fuzzing, and keep invariant coverage open or
blocked for the changed surface.

**Example 3:**
Input: A changed oracle config still returns a positive price, but the output is
`asset/ETH` while the consumer expects USD.
Output: Add a semantic expectation test that compares the configured result
against the expected USD composition with `check_oracle_semantics.sh` or an
equivalent test, and fail the review if the values diverge materially.
