# Diff SDL

Use this workflow when the SDL should follow recent changes rather than the
entire repository. Keep the analysis narrow so the threat model, tests, and
report all stay tied to the same diff evidence.

## Goal

1. Establish or refresh the relevant project threat model.
2. Use recent commits and diffs to identify threats on the changed surface.
3. Run STRIDE-Web3 for the changed surface.
4. Add and run integration tests, fuzzing, and invariant tests with no skip
   path.
5. Produce a detailed report grounded in git, code, and test evidence.

## Stage 1: Threat Model First

Build a compact but explicit threat model for the impacted parts of the system.
Even in `diff-sdl`, threat identification depends on a clear model of:

- assets
- trust boundaries
- roles and privileges
- external dependencies
- cross-contract data flow

Build this compact model before moving on when no usable baseline exists. This
prevents later findings from drifting away from the actual system assumptions.

Run the Trail of Bits threat-modeling stack from `tob-tooling.md` over the
changed files and nearby dependencies. Use:

- `entry-point-analyzer`
- `supply-chain-risk-auditor`
- `differential-review`
- `variant-analysis`
- `audit-context-building` for high-risk changed entry points

Use `semantic-validation.md` when the diff changes external touchpoints,
oracles, config keys, validators, or proposals.

## Stage 2: Diff-Centered Threat Identification

Use git history as the source of truth for what changed.

Collect at least this evidence set:

- current branch name
- recent commit timeline
- diff range
- changed files and changed functions
- diff hunks for Solidity changes
- runtime prerequisites inferred from repository tooling and docs

Preferred collection command:

```bash
./scripts/collect_change_scope.sh origin/main 20
```

When the user points to one specific PR commit, use an explicit parent-to-commit
range such as `commit^..commit`. This keeps the review tied to the requested
snapshot instead of accidentally absorbing later fixes on the same branch.

Before Stage 3, discover runtime prerequisites with:

```bash
./scripts/discover_runtime_requirements.sh .
```

Map each changed surface back to the threat model, then:

- map each changed function or integration point back to the threat model
- treat changed config rows, proposal arrays, and name-derived deployment keys
  as changed surfaces even when the diff does not modify a large function body
- identify new or altered trust assumptions
- identify new external touchpoints, role changes, oracle/config semantics, and
  state-machine changes
- run STRIDE-Web3 on the changed surfaces, not on unrelated untouched code

After threat identification, run the scoring and second-pass flow from
`risk-scoring.md` and write `risk-register.md`.

### Optional Threat Enrichment Pass

Read `references/threat-enrichment.md` when the user wants broader threat
ideation for the changed surface.

Use this pass after collecting the change scope:

1. Scope the review to changed files plus nearby dependencies.
2. Run five role-focused subagent passes:
   - Agent A: access control and privilege boundaries
   - Agent B: accounting, rounding, and invariant safety
   - Agent C: integrations, external calls, oracle usage, and trust assumptions
   - Agent D: state transitions, griefing, denial-of-service, and sequencing
   - Agent E: adversarial reasoning across multi-step exploit paths
3. Use candidate keywords suggested by the changed code to widen each agent's
   search space.
4. Promote a candidate into the SDL threat inventory only when local code, diff,
   test, or runtime evidence confirms it.

This pass improves threat discovery without weakening the evidence standard.

## Stage 3: Mandatory Verification

Treat this stage as a hard gate because diff-driven reviews are only credible
when behavior is exercised, not just described.

For every material changed threat surface:

- add or extend integration tests
- add or extend fuzz tests
- add or extend invariant tests
- add or extend semantic expectation tests when the surface can return
  plausible-but-wrong outputs

Stop and report the blocker when the repository or environment cannot run those
tests. Avoid narrative-only claims because they make regression review hard to
trust.

Use the verification stack from `tob-tooling.md`:

- `property-based-testing`
- `spec-to-code-compliance`
- optional `static-analysis`

Use `runtime-validation.md` to handle RPC, fork, tiered validation, and skip
policy. Use `semantic-validation.md` to carry oracle/config/validator checks
into Stage 3.

For changed oracle, config, accounting, or proposal surfaces, do not stop at
"no revert", "non-zero output", or "feed address was updated". Add at least one
check for expected-versus-observed behavior so the run can catch semantic
mispricing and other logic-level mismatches.

When changed oracle/config semantics are the main risk and the repository has a
slow or overly broad smoke suite, run `./scripts/check_oracle_semantics.sh`
against the changed feed and the expected canonical path. Keep the broad suite
as advisory if it times out or only proves liveness.

Prefer the repository's native proposal or integration-test harness over direct
`forge script` runs when multi-chain fork IDs, env bootstrap logic, or proposal
test scaffolding are encoded in tests. Report missing env vars such as
`PRIMARY_FORK_ID` or chain RPC URLs as runtime blockers first, then rerun with
the required inputs to distinguish environment failures from code failures.

## Stage 4: Detailed Report

Produce these artifacts:

- `sdl-output/diff-sdl/threat-model.md`
- `sdl-output/diff-sdl/change-threat-analysis.md`
- `sdl-output/diff-sdl/risk-register.md`
- `sdl-output/diff-sdl/test-verification.md`
- `sdl-output/diff-sdl/audit-preparation.md`
- `sdl-output/diff-sdl/final-report.md`
- `sdl-output/diff-sdl/final-report.pdf`

Use the exact structures from `reporting-requirements.md`. Include:

- which commits and functions were analyzed
- how the threat model changed
- the STRIDE-Web3 findings for new code
- how the risk register and second-pass review changed the final priorities
- which tests were added or run
- what remains unresolved

Write `final-report.md` first, then render `final-report.pdf` from the same
content so the markdown and PDF never drift apart. Use the
`audit-preparation.md` reference before final delivery, and use `ci-gates.md`
when the run needs strict completion or PR gating.

## Example

**Example 1:**
Input: Review the current branch against `origin/main`, identify new threats, and
prove coverage with integration, fuzz, and invariant tests.
Output: Run `diff-sdl`, collect the change scope, and write artifacts under
`sdl-output/diff-sdl/`.
