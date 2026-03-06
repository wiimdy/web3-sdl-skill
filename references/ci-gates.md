# CI Gates

Use this reference when the SDL run happens in CI, in a PR workflow, or under a
strict completion contract.

## Completion Rule

Do not mark the run complete until the required artifacts exist and are
non-empty.

For `project-sdl`, require:

- `sdl-output/project-sdl/threat-model.md`
- `sdl-output/project-sdl/risk-register.md`
- `sdl-output/project-sdl/test-verification.md`
- `sdl-output/project-sdl/audit-preparation.md`
- `sdl-output/project-sdl/final-report.md`
- `sdl-output/project-sdl/final-report.pdf`

For `diff-sdl`, require:

- `sdl-output/diff-sdl/threat-model.md`
- `sdl-output/diff-sdl/change-threat-analysis.md`
- `sdl-output/diff-sdl/risk-register.md`
- `sdl-output/diff-sdl/test-verification.md`
- `sdl-output/diff-sdl/audit-preparation.md`
- `sdl-output/diff-sdl/final-report.md`
- `sdl-output/diff-sdl/final-report.pdf`

## CI Failure Conditions

Fail CI when configured gates are hit, for example:

- a Critical or High invariant or property test fails
- coverage falls below the configured threshold
- a new Critical threat has no `Reduce` or `Avoid` response
- a high-severity semantic finding remains unresolved
- a required second-think log is missing
- a changed state-modifying function lacks diff-to-test mapping
- an oracle or config semantic trace is missing
- validator reverse-gap analysis is missing
- runtime is skipped without Tier 3 fallback evidence

Do not fail CI on static-analysis output alone unless local evidence
corroborates it.

## Example

**Example 1:**
Input: Run diff-sdl in PR mode and enforce the strict completion contract.
Output: Produce the full diff-sdl artifact set, then fail the run if a required
artifact or gate is missing.
