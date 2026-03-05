---
name: web3-sdl
description: Run Web3 SDL stages 1-4 with one deliverable per stage and a final PDF report.
---

# Web3 SDL Skill

You are performing a Security Development Lifecycle (SDL) analysis on a smart contract project.
Execute the 4 stages below sequentially.

Save outputs to the `sdl-output/` directory.

---

## Inputs

- A Foundry project (Solidity source, `foundry.toml`, tests, scripts).
- Optional: a config file `sdl-config.yml` at repo root to override defaults (coverage gates, risk scoring, external context like TVL).

## Output Contract (Strict)

Generate only these final artifacts:

1. `sdl-output/threat-model.md`
2. `sdl-output/risk-register.md`
3. `sdl-output/test-verification.md`
4. `sdl-output/audit-preparation.md`
5. `sdl-output/final-report.pdf`

Do not create additional top-level SDL artifact files in `sdl-output/`.
All supporting evidence (DFD, attack trees, diff context, tool summaries, runtime notes) must be embedded inside the stage document for that step.

---

## Grounding & Validation Rules (Mandatory)

1. Any new or changed external touchpoint must be explicitly analyzed in `threat-model.md`.
   - Detection source-of-truth must be recent current-branch commits (`git log` within `diff_scope.commit_window`) plus matching Solidity diffs.
   - Do not infer external touchpoints from untouched historical code outside the analyzed commit window.
   - Examples: dependency/import changes, new external calls/interfaces, new addresses/constants, bridge/cross-chain paths, role/governance dependencies, keeper/bot/off-chain assumptions.

2. Every High/Critical item must be grounded with concrete evidence in the stage document.
   - Acceptable evidence: code pointer (`path:line`), diff hunk excerpt, static-analysis snippet, test/runtime evidence.
   - Status must be one of: `Candidate / Confirmed / Rejected / Needs-Info`.
   - `Critical/High` is allowed only when:
     - `Confirmed`, or
     - runtime validation is impossible but rationale plus mitigation/monitoring is explicit.

3. Runtime validation is best-effort, but skip reasons must be explicit.
   - If RPC/fork/address prerequisites are missing, mark `SKIP` with required missing inputs.

4. Oracle Semantic Correctness is a mandatory threat class for oracle-integrated protocols.
   - Explicitly validate denomination/base-quote assumptions (for example, USD price vs ETH ratio).
   - For each changed oracle touchpoint, define protocol-expected unit as an invariant and verify observed unit.

5. Config and validator semantics must be analyzed beyond address existence.
   - For changed config keys, trace semantic meaning (unit, scale, orientation, conversion path), not only address presence.
   - For changed validator/proposal `validate*` functions, produce a reverse-gap list of what is NOT validated.

6. If fork/RPC validation is skipped, RPC-free semantic checks (Tier 3) are still mandatory.
   - `SKIP` is allowed only for RPC-required checks, not for static semantic checks.

7. Static-analysis findings are advisory unless corroborated.
   - Do not assign `High/Critical` from Slither-only output.
   - High/Critical classification requires at least one corroborating signal (semantic trace mismatch, test failure, runtime evidence, or direct code proof).

---

## Configuration (Optional)

If `sdl-config.yml` exists, use it to override defaults. If absent, use defaults below.

```yaml
project:
  chain: base
  tvl_usd: 250000000

diff_scope:
  base_ref: origin/main
  range: ""
  commit_window: 20
  gitlog_mode: first-parent
  diff_context_lines: 3

runtime_validation:
  enabled: true
  rpc_url_env: RPC_URL
  fork_block: null
  max_staleness_sec: 3600
  prompt_for_rpc_if_missing: true
  rpc_chain_prompt_required: true
  allow_user_decline_runtime_checks: true

risk_scoring:
  impact_map: {Critical: 4, High: 3, Medium: 2, Low: 1}
  likelihood_map: {High: 3, Medium: 2, Low: 1}

coverage_gates:
  enabled: true
  line_min: 0.90
  branch_min: 0.80
  function_min: 1.00

gating:
  block_on_new_critical_without_reduce: true
  block_on_critical_high_invariant_failure: true
  block_on_unresolved_high_severity_slither: false
  block_on_unresolved_high_severity_semantic: true

fp_control:
  second_pass_required: true
  min_disconfirming_checks_per_high_or_critical: 2
  block_on_missing_second_pass: true
  block_on_unmapped_changed_state_function: true

semantic_validation:
  oracle_semantic_correctness_required: true
  require_denomination_trace: true
  require_validate_gap_analysis: true
  block_on_unknown_oracle_denomination: true

integration_validation:
  require_outcome_based_checks: true
  require_economic_scenario_tests_for_value_surfaces: true
  require_validator_negative_tests: true
  require_pre_post_diff_result_comparison: true
  max_allowed_relative_drift: 0.05

skip_policy:
  enforce_tier3_without_rpc: true
  tier3_required_checks:
    - oracle_name_pattern_blacklist
    - config_key_denomination_inference
    - validate_gap_analysis
    - slither_blind_spot_review
```

Do not guess unknown context (for example TVL). Mark as `Unknown`.

---

## Prerequisites Check

Before starting, verify:

1. `forge build` succeeds.
2. Required Trail of Bits skills are installed:

```
/plugin install trailofbits/skills/plugins/entry-point-analyzer
/plugin install trailofbits/skills/plugins/audit-context-building
/plugin install trailofbits/skills/plugins/building-secure-contracts
/plugin install trailofbits/skills/plugins/property-based-testing
/plugin install trailofbits/skills/plugins/differential-review
/plugin install trailofbits/skills/plugins/supply-chain-risk-auditor
/plugin install trailofbits/skills/plugins/spec-to-code-compliance
/plugin install trailofbits/skills/plugins/variant-analysis
```

3. Optional best-effort tools:
   - `slither --version`
   - `/plugin install trailofbits/skills/plugins/static-analysis`
   - `semgrep --version`
   - `codeql version`
   - `echidna-test --version` and/or `medusa --version`

If any mandatory prerequisite is missing, stop and report it.

---

## Stage 1: Threat Modeling

Goal: identify what can go wrong from an attacker's perspective.

Mandatory diff-centered setup (current branch):

1. Resolve branch and diff scope.
   - If `diff_scope.range` is set, use it.
   - Otherwise use `diff_scope.base_ref...HEAD`.
2. Collect recent branch history and Solidity change hunks.
3. Keep this change intelligence as source-of-truth for Stage 2/3 traceability.

Mandatory semantic analysis from recent commits:

1. For each changed oracle/config touchpoint from the analyzed commit window, derive:
   - expected unit/invariant (what protocol assumes, e.g., USD)
   - observed unit/semantics (what feed/config likely returns, e.g., ETH ratio)
   - required conversion path (if any) and mismatch risk
2. Build a semantic trace chain:
   - `config key` -> `address/feed` -> `consumer function` -> `assumed denomination`
3. For changed validator/proposal functions (for example `validate*`), run reverse-gap analysis:
   - validated conditions
   - NOT validated conditions (explicit gaps)

Reference commands:

```bash
git rev-parse --abbrev-ref HEAD
git log --first-parent --oneline --max-count 20
git diff --unified=3 origin/main...HEAD -- '*.sol'
```

Run:

- `entry-point-analyzer`
- `supply-chain-risk-auditor`
- `audit-context-building` (for high-risk externally callable functions)
- `variant-analysis`
- `differential-review` scoped to changed Solidity functions/hunks

Build and save one file only: `sdl-output/threat-model.md`.

`threat-model.md` must include:

- System scope and trust boundaries
- Current branch and analyzed git range
- Recent commit timeline from current branch (`git log`, latest N by `commit_window`)
- Change scope from Git diff (`origin/main...HEAD` or configured range)
- Diff hunk-to-function mapping table for changed Solidity code
- New/changed external touchpoints and assumptions
- External touchpoint delta table derived from recent commits only:
  - commit hash
  - changed file/function
  - touchpoint type (import/interface/call/address/role/off-chain dependency)
  - evidence snippet (diff hunk)
  - downstream verification target ID
- External touchpoint semantic trace table derived from recent commits:
  - commit hash
  - config key / symbol / oracle identifier
  - expected denomination invariant (protocol-side)
  - observed denomination (feed/wrapper-side)
  - conversion path required
  - mismatch impact hypothesis
  - status (`Match / Mismatch / Unknown`)
- Entry points inventory
- Differential-review findings summary for changed surfaces
- STRIDE-Web3 threat list (`TM-xxx`) with status and evidence
- Oracle Semantic Correctness checklist:
  - denomination match (USD vs non-USD ratio)
  - base/quote orientation match
  - decimals/scale consistency
  - wrapper/feed semantic consistency
- Validator reverse-gap table:
  - function name
  - what it validates
  - what it does not validate
  - related threat IDs
- Composite attack scenarios
- DFD (Mermaid block inline)
- Attack trees (Mermaid block inline)
- Evidence appendix (code pointers, diff snippets, tool snippets)

Stage 1 fail condition:

- If branch/range/diff evidence or hunk-to-function mapping is missing, Stage 1 is incomplete.
- If external touchpoint decisions are not traceable to recent commit evidence, Stage 1 is incomplete.
- If changed oracle/config touchpoints lack denomination semantic trace, Stage 1 is incomplete.
- If changed validator/proposal functions lack reverse-gap analysis, Stage 1 is incomplete.

---

## Stage 2: Risk Assessment

Goal: prioritize Stage 1 threats.

For each threat:

1. Classify Impact using Immunefi v2.3 (Critical/High/Medium/Low).
2. Estimate Likelihood (High/Medium/Low).
3. Score using default mapping unless overridden:
   - Impact: Critical=4, High=3, Medium=2, Low=1
   - Likelihood: High=3, Medium=2, Low=1
   - `score = impact_value * likelihood_value`
   - Priority band default: 9-12=P0, 6-8=P1, 3-4=P2, 1-2=P3
4. Apply correction factors with explicit notes:
   - TVL magnitude
   - Upgradeability/timelock constraints
   - Pause/circuit-breaker coverage
   - Oracle/bridge/keeper dependency risk
   - Confirmed denomination/semantic mismatch in oracle path (raise priority)
5. Assign 4T response: `Transfer / Avoid / Accept / Reduce`.
   - Critical impact must not default to `Accept`.
6. Run a mandatory second-think pass for all `High/Critical` threats and all `P0/P1` items.
   - Perform at least `fp_control.min_disconfirming_checks_per_high_or_critical` disconfirming checks.
   - Required check types:
     - precondition falsification (what condition makes this non-exploitable)
     - contradictory code-path/state validation
     - counter-evidence from tests/static/runtime artifacts (when available)
7. Finalize status after second pass.
   - Track `First Pass` and `Second Pass` verdicts separately.
   - If severity remains High/Critical, state why disconfirming checks did not invalidate the claim.
8. For Oracle Semantic Correctness findings:
   - Treat confirmed denomination mismatch as a semantic integrity failure.
   - If mismatch can materially distort price, default to `P0/P1` unless strong compensating controls are proven.

Save one file only: `sdl-output/risk-register.md`.

`risk-register.md` must include:

- Summary counts by impact and priority
- Full risk register table
- Correction factors and assumptions
- Explicit `Reduce` targets for Stage 3
- First-pass vs second-pass verdict log
- False-positive disposition summary (`Rejected`, downgraded, retained) with reasons

---

## Stage 3: Testing & Verification

Goal: generate and execute verification for all `Reduce` targets.

Before running tools, build a diff-to-test matrix from Stage 1 change intelligence:

- For each changed state-modifying function, map at least one test (invariant/fuzz/unit) and linked threat IDs.
- If no test is possible, mark explicit exception with rationale and owner.
- For each changed oracle/config semantic touchpoint, map at least one semantic verification check.
- For each changed validator/proposal function, map at least one reverse-gap-derived check.

Outcome-based integration verification (general mandatory policy):

- Apply this policy whenever changed surfaces can affect value/risk/accounting semantics
  (for example price feeds, conversion paths, wrappers, risk params, accounting math, validators).
- Required test families:
  1. Result-value invariant checks:
     - verify consumer-facing outputs match declared semantic invariants (unit, scale, orientation, conversion path).
     - compare computed expected value vs protocol output with explicit tolerance.
  2. Economic behavior scenario checks:
     - execute end-user flows sensitive to those outputs (for example supply/borrow, mint/redeem, swap, liquidation path).
     - assert outcomes remain within expected risk envelopes.
  3. Validator negative tests:
     - prove invalid semantic configurations are rejected (revert/fail).
     - if accepted unexpectedly, mark as verification failure.
  4. Pre/post diff differential result checks:
     - run identical inputs on baseline vs changed code/config.
     - fail when relative drift exceeds `integration_validation.max_allowed_relative_drift` without approved rationale.

Runtime input gate (interactive, when needed):

- If Tier 1 runtime checks are planned and `runtime_validation.rpc_url_env` is missing/unset, pause and ask the user:
  - which chain RPC is required for this run
  - RPC endpoint (or env var name to use)
  - optional fork block
- Example prompt:
  - `Runtime checks require RPC. Which chain should be used (e.g., Ethereum/Base/Arbitrum), what is the RPC URL or env var, and optional fork block?`
- If the user provides values, continue Tier 1 checks.
- If the user declines or cannot provide RPC, continue with Tier 3 only and record explicit `SKIP` for Tier 1/2.

Run:

1. `property-based-testing` to generate Foundry tests (`test/sdl/`).
2. `spec-to-code-compliance`.
3. `static-analysis` (optional advisory signal: Slither/Semgrep/CodeQL if available).
4. Foundry execution:
5. Tiered validation execution (Tier 1/2/3).
6. Slither blind-spot review for semantic/config-level bug classes.

```bash
forge test --gas-report
forge coverage
```

Coverage gate defaults (if enabled): Line >= 90%, Branch >= 80%, Function = 100%.

Tiered validation policy:

- Tier 1 (RPC required): dynamic runtime checks (for example `getUnderlyingPrice()` sanity).
- Tier 2 (RPC optional): integration-context checks that benefit from fork/state.
- Tier 3 (RPC-free, mandatory): semantic static checks, including:
  - oracle name/key pattern checks (denomination hints)
  - config key denomination inference
  - oracle feed semantic trace consistency
  - validator reverse-gap checks
  - Slither blind-spot manual checks

Static-analysis confidence policy:

- Treat Slither output as low-confidence triage by default.
- Slither finding alone does not block release and does not set `High/Critical`.
- Use static-analysis output to prioritize targeted semantic/manual verification, not as final severity proof.

If RPC is unavailable:

- Tier 1 and Tier 2 may be `SKIP` with explicit reason.
- Tier 3 must still run and be recorded.

Diff-test gate:

- If any changed state-modifying function is unmapped and `fp_control.block_on_unmapped_changed_state_function` is true, Stage 3 fails.
- If any changed oracle/config touchpoint lacks semantic verification mapping, Stage 3 fails.
- If runtime is skipped but Tier 3 checks are missing and `skip_policy.enforce_tier3_without_rpc` is true, Stage 3 fails.
- If integration-affected surfaces are changed but required outcome-based test families are missing, Stage 3 fails.

Save one file only: `sdl-output/test-verification.md`.

`test-verification.md` must include:

- Diff-to-test matrix (changed function -> threat IDs -> tests)
- Reduce-target-to-test mapping
- Generated test files and purpose
- `forge test` summary (pass/fail, key failures)
- `forge coverage` summary vs configured gates
- Static/spec analysis summary (with SKIP reasons if tool missing)
- Runtime input log (requested chain, provided RPC/env, fork block, or decline reason)
- Slither blind-spot registry (bug classes Slither cannot detect, with manual compensating checks)
- Slither triage table with confidence labels (`Advisory / Corroborated / Rejected`)
- Tiered validation matrix (Tier 1/2/3, RPC required?, status, evidence)
- Oracle semantic verification results (denomination/base-quote/scale)
- Validator reverse-gap-derived verification checklist
- Result-value invariant test results (expected vs observed values and tolerances)
- Economic scenario test results (risk envelope assertions and deviations)
- Validator negative test results (invalid config acceptance/rejection)
- Pre/post diff differential result table (baseline vs changed outputs, relative drift, verdict)
- Unresolved high-severity findings and owner placeholders
- Unmapped changed functions and explicit disposition (`Covered / Exception / Gap`)

---

## Stage 4: Audit Preparation

Goal: package audit-ready context.

Run `building-secure-contracts` and consolidate findings from Stages 1-3.

Save one file only: `sdl-output/audit-preparation.md`.

`audit-preparation.md` must include:

- Project overview and scope snapshot
- SDL summary metrics (threat count, risk breakdown, verification status)
- Recommended P0/P1 audit focus
- Known accepted risks with rationale
- False-positive disposition summary from second-think pass
- Diff-to-test closure summary for changed state-modifying functions
- Oracle semantic correctness summary (matches/mismatches/unknowns)
- Runtime-skip fallback summary (what Tier 3 checks replaced fork checks)
- Validator reverse-gap closure summary
- Open questions and missing context
- Pre-audit action list with priority and owner placeholders

---

## Final Report PDF

Create a stakeholder-ready final report that merges key content from:

- `threat-model.md`
- `risk-register.md`
- `test-verification.md`
- `audit-preparation.md`

Then generate only: `sdl-output/final-report.pdf`.

Use a temporary Markdown file only for PDF rendering, then remove it:

```bash
pandoc /tmp/final-report.tmp.md -o sdl-output/final-report.pdf --from=gfm --pdf-engine=xelatex
```

Fallback:

```bash
npx md-to-pdf /tmp/final-report.tmp.md
mv /tmp/final-report.tmp.pdf sdl-output/final-report.pdf
```

If PDF generation fails, record the exact error in `audit-preparation.md` and stop.

Completion rule: do not mark SDL complete until these 5 files exist and are non-empty:

- `threat-model.md`
- `risk-register.md`
- `test-verification.md`
- `audit-preparation.md`
- `final-report.pdf`

---

## CI/CD Mode

When triggered by PR/CI:

1. Resolve branch, analyzed range, and recent commit window (`git log --first-parent`).
2. Detect changed Solidity files (`git diff --name-only origin/main...HEAD | grep '\\.sol$'`).
3. Run `differential-review`, but embed results into `threat-model.md` (do not emit separate diff artifacts).
4. Enforce semantic trace for changed oracle/config touchpoints from recent commits.
5. Enforce reverse-gap analysis for changed validator/proposal functions.
6. Scope Stages 1-3 to changed contracts plus direct dependencies.
7. Enforce second-think pass for all High/Critical and P0/P1 items.
8. Enforce diff-to-test mapping completeness for changed state-modifying functions.
9. Enforce Tier 3 RPC-free checks whenever runtime checks are skipped.
10. Produce the same 5 artifacts only.
11. Fail CI when configured gating conditions are met:
   - Critical/High invariant/property test failure
   - Coverage below gate (if enabled)
   - New Critical threat without `Reduce` or `Avoid`
   - Unresolved high-severity semantic finding
   - Missing second-think log for High/Critical or P0/P1 items
   - Missing diff-to-test mapping for changed state-modifying functions
   - Missing oracle semantic trace for changed oracle/config entries
   - Missing validator reverse-gap analysis for changed validator/proposal functions
   - Runtime skipped without Tier 3 fallback evidence
   - Note: Slither-only findings do not block CI unless corroborated by semantic/test/runtime evidence.
