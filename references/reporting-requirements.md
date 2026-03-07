# Reporting Requirements

End every run with a detailed written report grounded in SDL artifacts rather
than generic commentary. A stable report structure makes reviews easier to
compare across branches, projects, and reruns.

## Report Structure

ALWAYS use this exact structure for `final-report.md`:

```markdown
# Web3 SDL Report
## Engagement Snapshot
## Executive Summary
## Scope
## System Overview
## Review Context
## Findings Overview
## Detailed Findings
## Verification Summary
## Residual Risks
## Recommendations
## Appendix
```

Use this structure because it reads more like a professional audit report:

- `Engagement Snapshot` and `Findings Overview` make the result scannable
- `System Overview`, `Privileged Roles`, and `Trust Assumptions` keep the
  report grounded in the security model
- `Detailed Findings` separates impact, evidence, and remediation clearly
- `Verification Summary` keeps tests and evidence easy to audit later

Render `final-report.pdf` from the completed `final-report.md`. Keep the
markdown file as the source of truth so the PDF stays reproducible and easy to
diff. If a rich PDF engine is unavailable, use the script fallback renderer and
record that the PDF formatting is degraded rather than blocking delivery on a
missing LaTeX package alone.

## Consistency Rules

Keep the final report visually stable across reruns:

- Keep the main `##` headings exactly as defined in the structure above.
- Keep `Engagement Snapshot` to the exact 7-row table from the outline.
- Keep `Executive Summary` to 2 to 4 short paragraphs.
- Keep finding titles under roughly 90 characters so the TOC and findings table
  do not become layout-dependent.
- Keep `Surface` and `Verification` cells compact. Move nuance into the finding
  body instead of stretching the overview table.
- Prefer bullets in `Technical Details`, `Evidence`, and `Recommendation`.
- Record long command output in `test-verification.md`, then summarize it in the
  final report. This keeps PDF pagination more consistent.

## Supporting Artifact Structures

Use these exact structures for the stage artifacts.

### Threat Model

ALWAYS use this exact structure for `threat-model.md`:

```markdown
# Threat Model
## Scope
## Assets And Security Objectives
## Trust Boundaries
## Actors And Roles
## Entry Points
## External Dependencies
## Threat Inventory
## STRIDE-Web3 Notes
## Evidence Appendix
```

### Risk Register

Use this exact structure for `risk-register.md`:

```markdown
# Risk Register
## Scope
## Severity Model
## Risk Table
## Mitigations
## Residual Risks
## Recommended Next Actions
```

### Audit Preparation

Use this exact structure for `audit-preparation.md`:

```markdown
# Audit Preparation
## Scope Snapshot
## SDL Summary Metrics
## Recommended Audit Focus
## Accepted Risks
## False-Positive Disposition
## Diff-To-Test Closure
## Semantic Validation Summary
## Runtime Fallback Summary
## Open Questions
## Pre-Audit Actions
```

### Test Verification

ALWAYS use this exact structure for `test-verification.md`:

```markdown
# Test Verification
## Scope
## Commands Run
## Threat-To-Test Mapping
## Added Or Modified Tests
## Results
## Failures And Their Meaning
## Blockers
```

### Change Threat Analysis

Use this exact structure for `change-threat-analysis.md` in `diff-sdl`:

```markdown
# Change Threat Analysis
## Scope
## Commit Timeline
## Diff Summary
## Changed Functions
## New Or Changed Trust Assumptions
## STRIDE-Web3 Findings
## Verification Targets
## Open Questions
```

## Evidence Rules

Link every finding back to at least one of:

- file and line references
- diff hunk references
- commit hashes
- test file references
- command output summaries

Show why a finding is classified the way it is. This keeps the report useful to
engineers who need to validate or challenge the conclusion later.

## Workflow-Specific Emphasis

Emphasize these points in `project-sdl`:

- architecture and trust boundaries
- system-wide critical assets
- cross-component threat chains
- baseline privileged roles and trust assumptions

Emphasize these points in `diff-sdl`:

- analyzed git range
- recent commit timeline
- changed function mapping
- STRIDE-Web3 results for the changed surface
- exact tests added or run for the new threats
- expected-versus-observed mismatches that show logic-level divergence even
  when smoke checks pass
- the specific trust assumptions introduced or changed by the diff

## Subsection Expectations For `final-report.md`

Use these subsections inside the main report headings when they add clarity:

- `## Scope`
  - `### Review Objectives`
  - `### In Scope`
  - `### Out Of Scope`
  - `### Evidence Sources`
- `## System Overview`
  - `### Architecture Summary`
  - `### Privileged Roles`
  - `### Trust Assumptions`
  - `### Critical Assets And Security Properties`
- `## Review Context`
  - `### Workflow And Stage Coverage`
  - `### Change Overview` for `diff-sdl`
  - `### New Or Changed Trust Assumptions`
- `## Verification Summary`
  - `### Verification Matrix`
  - `### Commands Run`
  - `### Coverage Assessment`
  - `### Blockers`
- `## Recommendations`
  - `### Immediate Actions`
  - `### Near-Term Hardening`
  - `### Monitoring And Follow-Up Review`
- `## Appendix`
  - `### Files And Commits Reviewed`
  - `### Runtime And Environment Notes`
  - `### Open Questions`

## Findings Formatting

Start with a one-table `Findings Overview`, then write one subsection per
finding under `Detailed Findings`.

Use this exact table shape for the overview:

| ID | Title | Severity | Status | Surface | Verification |
| --- | --- | --- | --- | --- | --- |
| `F-101` | `Oracle semantic mismatch` | `Critical` | `Confirmed` | `Base cbETH` | `drift helper failed` |

Use this exact detail pattern for each finding:

```markdown
### [ID] [Short Title]
**Severity:** Critical
**Status:** Confirmed
**Category:** business logic
**Affected Surface:** Contract or path

#### Why This Matters
#### Technical Details
#### Evidence
#### Recommendation
#### Resolution Status
```

This layout makes findings easier to skim, compare, and convert into fix tasks.

## PDF Deliverable

Produce both:

- `final-report.md`
- `final-report.pdf`

Render the PDF with `scripts/render_final_report.sh` after the markdown is
complete. Treat the absence of any renderer as a blocker. If the script falls
back to the plain-text renderer, keep the artifact and record the degraded
formatting in `test-verification.md`.

## PDF Dependencies

Expect these dependencies when rendering `final-report.pdf`:

- `pandoc`
- a PDF engine supported by `pandoc`, such as `xelatex`, `wkhtmltopdf`, or
  `weasyprint`
- `python3` for the plain-text fallback renderer when rich PDF engines are not
  available or fail at runtime

If the repository sets a preferred PDF engine, use that engine consistently so
the layout stays stable across reruns.

## Example

**Example 1:**
Input: Produce a diff-driven SDL report for the current branch.
Output: Write `final-report.md` with the exact headings from `# Web3 SDL Report`
through `## Appendix`, include a dashboard-style snapshot, a findings overview
table, detailed findings with explicit evidence and remediation, then render
`final-report.pdf` with `render_final_report.sh`.
