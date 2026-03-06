# Audit Preparation

Use this reference during Stage 4 and final delivery. This restores the
`audit-preparation.md` artifact from the earlier monolithic skill.

## Goal

Package the repository state, threat inventory, verification posture, and open
questions into an audit-ready handoff before the final report is rendered.

## Trail Of Bits Audit Handoff

Run `building-secure-contracts` and consolidate its output with the earlier SDL
artifacts.

Use the artifact to summarize:

- project scope and architecture snapshot
- threat count and risk distribution
- verification status
- unresolved questions
- pre-audit action items

## Output

Write `audit-preparation.md` using the structure from
`references/reporting-requirements.md`.

Then merge the key content from:

- `threat-model.md`
- `risk-register.md`
- `test-verification.md`
- `audit-preparation.md`

into `final-report.md`, and finally render `final-report.pdf`.

## Example

**Example 1:**
Input: Stage 1 through Stage 3 are complete and the review needs an audit-ready
handoff.
Output: Run `building-secure-contracts`, write `audit-preparation.md`, then use
that artifact plus the earlier stage files to assemble the final report.
