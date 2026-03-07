# Web3 SDL Report

Use these formatting constraints to keep the PDF stable and readable:

- Keep the main `##` headings exactly as written below so the TOC stays stable.
- Keep `Engagement Snapshot` to the exact 7-row dashboard table.
- Keep `Executive Summary` to 2 to 4 short paragraphs, 2 to 4 sentences each.
- Keep finding titles under roughly 90 characters.
- Keep `Technical Details`, `Evidence`, and `Recommendation` mostly in bullets,
  not long narrative blocks.
- If a finding title is getting too long, move the nuance into `Technical
  Details` instead of stretching the heading.
- Prefer consistent sentence-case wording over creative heading variations.

## Engagement Snapshot

| Field | Value |
| --- | --- |
| Workflow | `project-sdl` or `diff-sdl` |
| Repository | `org/repo` |
| Branch / Ref | `branch-name` |
| Commit Range | `base..head` |
| Review Date | `YYYY-MM-DD` |
| Primary Outcome | `Pass` / `Fail` / `Blocked` |
| Final Deliverables | `final-report.md`, `final-report.pdf`, supporting artifacts |

Use this section like an audit-firm dashboard. Make it possible to understand
the engagement in under 20 seconds.

## Executive Summary

Write 2 to 4 short paragraphs:

1. State what was reviewed and why it matters.
2. State the highest-priority conclusion in plain language.
3. State whether the run found a release blocker, critical weakness, or only
   hardening items.
4. State whether verification passed, failed, or was partially blocked.

Then include a compact severity summary table:

| Severity | Count | Notes |
| --- | --- | --- |
| Critical | `0` | `release-blocking findings` |
| High | `0` | `serious but non-critical findings` |
| Medium | `0` | `important correctness or coverage gaps` |
| Low | `0` | `lower-risk issues or hygiene items` |
| Informational | `0` | `notes and observations` |

Keep the summary table to exactly these five severity rows so the cover page and
TOC stay visually consistent across reruns.

## Scope

### Review Objectives

- State the review goal in one sentence.
- State the top 2 to 4 questions the run needed to answer.

### In Scope

- List repositories, directories, contracts, proposals, or services reviewed.
- State exact commits or diff ranges.

### Out Of Scope

- List important exclusions explicitly.
- Note whether tests, off-chain systems, tokenomics, governance process, or
  external dependencies were assumed rather than validated.

### Evidence Sources

- `git log`
- `git diff`
- code review
- local tests
- runtime checks
- external docs or postmortems used for comparison

## System Overview

### Architecture Summary

Write a short explanation of the system or changed subsystem. Focus on value
flow, control flow, and external integrations.

### Privileged Roles

| Role | Authority | Security Relevance |
| --- | --- | --- |
| `DEFAULT_ADMIN_ROLE` | `...` | `...` |

### Trust Assumptions

- State what the system assumes about privileged actors.
- State what the system assumes about oracle feeds, bridges, routers, keepers,
  or external protocols.
- State what the review assumed because it could not be fully verified.

### Critical Assets And Security Properties

| Asset / Property | Why It Matters | Failure Mode |
| --- | --- | --- |
| `oracle denomination correctness` | `borrowing and liquidation depend on it` | `semantic mispricing` |

## Review Context

### Workflow And Stage Coverage

| Stage | Purpose | Result |
| --- | --- | --- |
| Stage 1 | Threat model | `Completed` |
| Stage 2 | Diff analysis / STRIDE-Web3 | `Completed` |
| Stage 3 | Verification | `Completed` / `Partially blocked` |
| Stage 4 | Reporting | `Completed` |

### Change Overview

Use this section for `diff-sdl`. If the run used `project-sdl`, replace it with
the baseline architecture or component map that mattered most to the review.

| Surface | Change Type | Risk Relevance |
| --- | --- | --- |
| `ChainlinkOracleConfigs` | `config expansion` | `changes market pricing semantics` |

### New Or Changed Trust Assumptions

- Record assumptions introduced or modified by the diff.
- Highlight assumptions that were not enforced by tests or validators.

## Findings Overview

Provide one table before the detailed findings.

| ID | Title | Severity | Status | Surface | Verification |
| --- | --- | --- | --- | --- | --- |
| `F-101` | `Raw ratio feed wired into USD consumer path` | `Critical` | `Confirmed` | `Base cbETH oracle config` | `semantic drift check failed` |

Use this table like an audit-firm findings summary page. It should be easy to
scan and prioritize.

Keep the `Surface` and `Verification` columns terse. If the description gets
long, move the detail down into the finding body.

## Detailed Findings

Use one subsection per finding:

### `[ID] [Short Title]`

**Severity:** `Critical` / `High` / `Medium` / `Low` / `Informational`  
**Status:** `Confirmed` / `Candidate` / `Rejected` / `Needs-Info`  
**Category:** `STRIDE-Web3 class`, `business logic`, `access control`,
`numerics`, `configuration`, or similar  
**Affected Surface:** `contract:function`, config rows, proposal path, test path

#### Why This Matters

State the impact in plain language. Explain what can go wrong for users,
operators, or protocol safety.

#### Technical Details

- Describe the failure mode.
- Describe the exploit path or incorrect state transition.
- Explain why existing checks did not catch it.

#### Evidence

- file and line references
- diff evidence
- test or runtime evidence
- relevant command output summary

#### Recommendation

- State the immediate fix.
- State the follow-up hardening or test needed.

#### Resolution Status

- `Open`
- `Mitigated locally`
- `Fixed upstream`
- `Acknowledged`

Keep each finding body tight:

- `Why This Matters`: 1 short paragraph
- `Technical Details`: 3 to 6 bullets
- `Evidence`: 2 to 5 bullets
- `Recommendation`: 1 to 3 bullets

## Verification Summary

### Verification Matrix

| Threat / Finding | Integration | Fuzz | Invariant | Semantic / Differential | Result |
| --- | --- | --- | --- | --- | --- |
| `F-101` | `proposal harness` | `n/a` | `none` | `oracle drift helper` | `Fail` |

### Commands Run

| Command | Purpose | Result | Notes |
| --- | --- | --- | --- |
| `forge build` | `compile` | `Pass` | `...` |

### Coverage Assessment

- State what was verified directly.
- State what only had partial coverage.
- State which smoke checks were insufficient and why.

### Blockers

- Record blockers that prevented stronger evidence.
- Distinguish environment blockers from code defects.
- Record whether the PDF used the rich renderer or the plain-text fallback.

## Residual Risks

- Record unresolved risks after the current fixes or recommendations.
- Record risks accepted by scope limits, missing tests, or external trust.

## Recommendations

### Immediate Actions

1. List release-blocking or incident-response actions.
2. Keep these concrete and short.

### Near-Term Hardening

1. List test additions, validator changes, monitoring, or config hardening.

### Monitoring And Follow-Up Review

1. List runtime signals worth watching.
2. List follow-up review tasks if another pass is required.

## Appendix

### Files And Commits Reviewed

- List the key files and commit hashes.

### Runtime And Environment Notes

- RPC assumptions
- fork assumptions
- special test harness notes

### Open Questions

- Record unresolved questions that still matter for a future review.
