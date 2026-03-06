# Project SDL

Use this workflow to produce a repository-wide SDL baseline. Favor breadth over
diff depth so the report captures the real system model before local changes
bias the analysis.

## Goal

Build a full threat model for the system, identify project-wide threats, verify
the most important risk surfaces with tests, and produce a detailed baseline
report.

## Stage 1: Full Threat Model

Build a project-wide threat model that covers:

- system scope and major components
- critical assets and security objectives
- trust boundaries and privileged roles
- entry points and state-changing flows
- external dependencies and integration assumptions
- system-wide STRIDE-Web3 threats
- DFD and attack-tree views where they materially improve clarity

Anchor the core threat list to the architecture rather than recent diffs unless
the user explicitly asks for a diff overlay. This keeps the baseline stable and
useful for later reviews.

Run the repository-wide Trail of Bits stack from `tob-tooling.md`. Use
`entry-point-analyzer`, `supply-chain-risk-auditor`, `variant-analysis`, and
`audit-context-building` to deepen the threat model. Use
`semantic-validation.md` whenever oracle, config, validator, or proposal
semantics matter.

## Stage 2: Threat Identification and Prioritization

Translate the threat model into a prioritized threat register.

Use `risk-scoring.md` for severity, likelihood, 4T response, and second-pass
false-positive control.

For each threat, record:

- assign severity and likelihood
- describe the exploit path and affected assets
- record mitigations, existing controls, and residual risk
- map the threat to concrete code locations or architectural boundaries

## Stage 3: Verification

Verify the highest-risk surfaces rather than every file in the repository. This
keeps the baseline credible without turning it into an unbounded test rewrite.

Cover these validation themes:

- end-to-end integration flows across core contracts
- fuzzing for boundary conditions, role misuse, and unexpected sequencing
- invariant tests for accounting, authorization, solvency, or state-machine
  properties

Add or extend test harnesses when key risks have no useful coverage. Report the
blocker with enough detail for the user to act on it when execution is blocked.

Use `property-based-testing`, `spec-to-code-compliance`, and optional
`static-analysis` as described in `tob-tooling.md`. Use
`runtime-validation.md` when runtime-backed checks or fork tests are useful.

## Stage 4: Detailed Baseline Report

Produce these artifacts:

- `sdl-output/project-sdl/threat-model.md`
- `sdl-output/project-sdl/risk-register.md`
- `sdl-output/project-sdl/test-verification.md`
- `sdl-output/project-sdl/audit-preparation.md`
- `sdl-output/project-sdl/final-report.md`
- `sdl-output/project-sdl/final-report.pdf`

Use the exact structures from `reporting-requirements.md`. Consistent output
makes the baseline easier to compare across repositories and over time. Write
`final-report.md` first, then render `final-report.pdf` from the same content.
Use the `audit-preparation.md` reference to create an audit-ready handoff before
the final report.

## Example

**Example 1:**
Input: Produce the first SDL for this protocol and map all trust boundaries.
Output: Run `project-sdl`, then write artifacts under `sdl-output/project-sdl/`.
