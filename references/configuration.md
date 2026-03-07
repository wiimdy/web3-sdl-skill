# Configuration

Read `sdl-config.yml` when the repository provides one. Keep the schema lean so
the skill stays easy to route and easy to override.

## Suggested Shape

```yaml
project:
  chain: base
  tvl_usd: null

mode:
  default: diff-sdl
  allow_stage_selection: true

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
  allow_user_decline_runtime_checks: false
  block_on_missing_rpc_for_required_checks: true

risk_scoring:
  impact_map: {Critical: 4, High: 3, Medium: 2, Low: 1}
  likelihood_map: {High: 3, Medium: 2, Low: 1}

testing:
  require_integration: true
  require_fuzz: true
  require_invariants: true
  allow_skip: false

coverage_gates:
  enabled: true
  line_min: 0.90
  branch_min: 0.80
  function_min: 1.00

gating:
  block_on_new_critical_without_reduce: true
  block_on_critical_high_invariant_failure: true
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
  max_relative_drift: 0.05

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

external_enrichment:
  enable_subagent_pass: true
  use_solidity_auditor: false
  candidate_keywords:
    - oracle
    - rounding
    - shares
    - liquidation
    - reentrancy
    - upgrade
    - role
    - permit

reporting:
  output_root: sdl-output
  include_commit_timeline: true
  include_stride_web3_table: true
  render_pdf: true
  pdf_tool: pandoc
  pdf_engine: ""
  pdf_fallback: plaintext
```

## Guidance

- Set `project.chain` and `project.tvl_usd` when those values materially affect
  risk prioritization.
- Set `mode.default` to the repository's common use case.
- Use `diff_scope` only for `diff-sdl`.
- Use `runtime_validation` when fork, RPC, or live-state checks matter.
- Keep `block_on_missing_rpc_for_required_checks: true` when a `diff-sdl` run
  should treat missing RPC as a blocker rather than a soft skip.
- Set `allow_user_decline_runtime_checks: false` when runtime-backed proposal or
  integration evidence is mandatory for sign-off.
- Keep `risk_scoring`, `fp_control`, `semantic_validation`, and `skip_policy`
  aligned with the repository's audit rigor.
- Use `semantic_validation.max_relative_drift` to turn semantic oracle checks
  into a deterministic pass or fail condition.
- Keep `allow_skip: false` for `diff-sdl` so the verification contract stays
  credible.
- Use `external_enrichment` only when the repository or user wants extra threat
  ideation from subagents.
- Keep `render_pdf: true` when `final-report.pdf` is part of the deliverable.
- Set `pdf_tool` and `pdf_engine` when the environment requires a stable export
  path.
- Keep `pdf_fallback: plaintext` when you want a deterministic backup renderer
  instead of a hard failure on missing LaTeX packages.
- Add extra keys only when the skill genuinely needs them during execution.

## Example

**Example 1:**
Input: Most reviews in this repository are PR-driven and need to run all
test categories.
Output:

```yaml
project:
  chain: base
  tvl_usd: 250000000

mode:
  default: diff-sdl
  allow_stage_selection: true

runtime_validation:
  enabled: true
  rpc_url_env: BASE_RPC_URL
  allow_user_decline_runtime_checks: false
  block_on_missing_rpc_for_required_checks: true

risk_scoring:
  impact_map: {Critical: 4, High: 3, Medium: 2, Low: 1}
  likelihood_map: {High: 3, Medium: 2, Low: 1}

testing:
  require_integration: true
  require_fuzz: true
  require_invariants: true
  allow_skip: false

external_enrichment:
  enable_subagent_pass: true
  use_solidity_auditor: true
  candidate_keywords:
    - oracle
    - rounding
    - shares
    - liquidation

fp_control:
  second_pass_required: true
  min_disconfirming_checks_per_high_or_critical: 2

semantic_validation:
  oracle_semantic_correctness_required: true
  require_denomination_trace: true
  require_validate_gap_analysis: true
  max_relative_drift: 0.05

reporting:
  render_pdf: true
  pdf_tool: pandoc
  pdf_engine: xelatex
  pdf_fallback: plaintext
```
