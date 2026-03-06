# Trail Of Bits Tooling

Use this reference whenever the SDL run needs the old Trail of Bits-driven
analysis depth. This reference restores the strong threat-modeling and
diff-analysis workflow from the earlier monolithic skill while keeping the new
modular layout.

## Required Skills

Make these Trail of Bits skills available before you rely on this workflow:

- `entry-point-analyzer`
- `audit-context-building`
- `building-secure-contracts`
- `property-based-testing`
- `differential-review`
- `supply-chain-risk-auditor`
- `spec-to-code-compliance`
- `variant-analysis`

Treat missing required skills as blockers for the full-strength workflow.

## Advisory Tools

Use these as best-effort supporting tools when available:

- `static-analysis`
- `slither`
- `semgrep`
- `codeql`
- `echidna-test`
- `medusa`

Treat these tools as accelerators and corroboration sources, not as substitutes
for local code reasoning.

## Threat Modeling And Diff Analysis Flow

Run this sequence in `diff-sdl`:

1. Collect the change scope from git.
2. Run `entry-point-analyzer` on the changed files and nearby dependencies.
3. Run `supply-chain-risk-auditor` on the same scoped surface to spot risky
   dependencies and trust anchors.
4. Run `differential-review` over the changed Solidity files and hunks.
5. Run `variant-analysis` on any plausible issue pattern surfaced by the diff.
6. Run `audit-context-building` on high-risk externally callable functions or
   flows that remain ambiguous after the first pass.

Run this sequence in `project-sdl`:

1. Run `entry-point-analyzer` over the repository or selected core scope.
2. Run `supply-chain-risk-auditor` over the same scope.
3. Run `variant-analysis` on the highest-risk patterns.
4. Run `audit-context-building` on critical flows and privileged operations.
5. Run `differential-review` only when the baseline also needs a change overlay.

## Verification Flow

Use these Trail of Bits skills during Stage 3:

- `property-based-testing` to design and add fuzz or invariant coverage
- `spec-to-code-compliance` to compare implementation behavior with the claimed
  design or security assumptions
- `static-analysis` as an advisory signal when installed

## Audit Preparation Flow

Use `building-secure-contracts` during Stage 4 to package the repository state,
testing posture, and audit focus into an audit-ready handoff.

## Output Handling

Embed summaries from Trail of Bits skills into the SDL artifacts instead of
creating extra top-level files. This keeps the deliverable set stable while
preserving the stronger analysis trace.

## Example

**Example 1:**
Input: Run diff-sdl on the current branch with the full old Trail of Bits-based
analysis stack.
Output: Collect the diff, run `entry-point-analyzer`, `supply-chain-risk-auditor`,
`differential-review`, `variant-analysis`, and `audit-context-building` on the
scoped surface, then carry their evidence into the SDL artifacts.
