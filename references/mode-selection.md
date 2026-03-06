# Mode Selection

Select one workflow before loading the detailed instructions.

## Choose `project-sdl`

Choose `project-sdl` when the user wants:

- a complete repository-wide SDL
- the first threat model for a project
- system architecture, trust boundaries, and asset mapping
- a broad review before diff-specific work

## Choose `diff-sdl`

Choose `diff-sdl` when the user wants:

- review of new code, a branch, a PR, or recent commits
- `git log` and `git diff` to drive the analysis
- threat identification tied to changed functions and integrations
- STRIDE-Web3 focused on newly introduced risk
- integration, fuzz, and invariant validation tied to the changed surface

## Decision Rules

- Choose `diff-sdl` when the request mentions "new code", "recent commits",
  "PR", "diff", "regression", or "what changed".
- Choose `project-sdl` when the request mentions "overall SDL", "whole
  project", "baseline", or "architecture".
- Build a compact project threat model for the impacted components first when
  `diff-sdl` is selected without a usable baseline. This keeps diff findings
  tied to the same assets, roles, and trust boundaries as the later report.

## Stage Requests

- Stage 1 only: produce just the threat model.
- Stage 2 only: build or load Stage 1 first, then identify threats.
- Stage 3 only: build or load Stage 1 and a threat-to-test matrix first.
- Stage 4 only: load prior stage artifacts first.

## Examples

**Example 1:**
Input: Review the whole repository and produce a baseline SDL.
Output: Choose `project-sdl`.

**Example 2:**
Input: Review the last 15 commits and identify new threats in changed contracts.
Output: Choose `diff-sdl`.

## Load Sequence

1. Chosen workflow file
2. `testing-requirements.md`
3. `reporting-requirements.md`
4. `configuration.md` only if config tuning is needed
