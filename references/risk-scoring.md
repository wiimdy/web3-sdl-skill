# Risk Scoring

Use this reference whenever Stage 2 or any later stage needs a prioritized risk
register. This restores the quantitative and false-positive-control logic from
the earlier monolithic skill.

## Goal

Prioritize threat candidates with explicit severity, likelihood, response, and
second-pass validation before Stage 3 spends time on verification.

## Scoring Flow

For each threat:

1. Classify impact with the repository's severity model.
2. Estimate likelihood.
3. Compute a score from the configured mappings unless the repository overrides
   them.
4. Apply correction factors such as TVL, upgradeability, pause controls,
   oracle/bridge dependency risk, or semantic mismatches.
5. Assign a 4T response:
   - `Transfer`
   - `Avoid`
   - `Accept`
   - `Reduce`

Do not default a Critical-impact issue to `Accept`.

## Second-Pass False-Positive Control

Run a second-think pass for:

- all `High` and `Critical` threats
- all `P0` and `P1` items

Perform at least the configured number of disconfirming checks, for example:

- precondition falsification
- contradictory code-path or state validation
- counter-evidence from tests, static analysis, or runtime artifacts

Keep both the first-pass and second-pass verdicts in the record.

## Oracle Semantic Priority Rule

Treat a confirmed oracle denomination or semantic mismatch as a semantic
integrity failure. Raise it toward `P0` or `P1` unless the repository proves
strong compensating controls.

## Output

Write `risk-register.md` using the structure from
`references/reporting-requirements.md`.

Include:

- summary counts by impact and priority
- the full risk table
- correction factors and assumptions
- explicit `Reduce` targets for Stage 3
- first-pass versus second-pass verdicts
- false-positive dispositions

## Example

**Example 1:**
Input: A changed liquidation path looks exploitable but depends on a narrow
oracle precondition.
Output: Score the issue, run second-pass disconfirming checks on the oracle
assumption, and record both verdicts before deciding whether Stage 3 must
validate it.
