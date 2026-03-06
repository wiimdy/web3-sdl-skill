# Threat Enrichment

Use this reference in `diff-sdl` when you want extra threat ideation beyond the
core repository analysis. Run this pass after collecting the change scope and
before finalizing the threat inventory.

## Goal

Generate stronger threat candidates from role-focused subagent passes over
changed code and nearby dependencies.

Treat this pass as idea generation, not automatic evidence. Promote a candidate
only after you confirm it with local code, diff, test, or runtime evidence.

## Scope

Start from:

- changed Solidity files
- changed functions
- contracts directly imported by the changed files
- contracts directly called by the changed files
- interfaces, libraries, or inherited parents that materially shape the changed
  behavior

Keep the scope narrow. The goal is to inspect the changed surface and the
dependencies that can alter its security properties, not to rescan the whole
repository.

## Subagent Pass

Split the threat pass by security concern so each worker can reason deeply about
one risk family.

Use this role split:

- Agent A: access control and privilege boundaries
- Agent B: accounting, rounding, and invariant safety
- Agent C: integrations, external calls, oracle usage, and trust assumptions
- Agent D: state transitions, griefing, denial-of-service, and sequencing
- Agent E: adversarial reasoning across multi-step exploit paths

Give every worker:

- the branch and diff range
- the changed files and changed functions
- the nearby dependency set
- the current compact threat model

Ask each worker to return:

- threat candidate ID
- affected files and functions
- exploit hypothesis
- preconditions
- why the changed code may have introduced or worsened the risk
- what local evidence would confirm or reject the candidate

## Solidity-Auditor Integration

If the user has installed the Pashov `solidity-auditor` Claude Code command,
use it as an extra reviewer over the changed files and nearby dependencies.

Use it for:

- fast security review over the scoped Solidity files
- adversarial idea generation
- surfacing issue patterns that deserve local follow-up

Do not treat its output as final findings. Convert its output into threat
candidates, then validate them against the local repository.

## Candidate Keywords

Use candidate keywords to widen the agent hypotheses when the changed code hints
at specific bug classes.

Start from keywords such as:

- `oracle`
- `rounding`
- `shares`
- `liquidation`
- `reentrancy`
- `upgrade`
- `role`
- `permit`

Expand the keywords when the change surface suggests a more specific concept,
for example:

- `price feed decimals`
- `exchange rate`
- `vault share inflation`
- `delegatecall upgrade`
- `signature replay`

Use these keywords to:

- steer subagent attention toward plausible bug classes
- refine exploit hypotheses
- identify missing negative tests or invariants

## Candidate Acceptance Rule

Accept a threat candidate into the SDL deliverables only when at least one of
these is true:

- the code or diff directly demonstrates the risk
- a test fails or a new test reproduces the issue
- a runtime check reproduces the issue
- the threat model plus local implementation details show a concrete mismatch

Keep rejected or weak candidates in analyst notes only. Do not elevate them into
the final threat inventory.

## Success Criteria

This pass is successful when:

- each agent role has inspected the scoped surface
- every promoted threat candidate links back to local repository evidence
- the final report clearly separates candidate ideation from confirmed local
  findings

## Example

**Example 1:**
Input: Review the changed vault withdrawal flow and use subagents to widen the
threat search.
Output: Collect the diff scope, inspect changed files plus nearby dependencies,
run the five role-focused passes with `shares`, `rounding`, and `liquidation`
as candidate keywords, then promote only locally verified candidates.
