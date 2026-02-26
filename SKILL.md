# Web3 SDL Skill

You are performing a Security Development Lifecycle analysis on a smart contract project. Execute the 4 stages below sequentially. Each stage produces output that feeds into the next.

Save all outputs to the `sdl-output/` directory.

## Prerequisites Check

Before starting, verify:
1. Run `forge build` — must succeed. If it fails, inform the user.
2. Run `slither --version` — Slither must be installed. If not, tell the user to run `pip install slither-analyzer`.
3. The following Trail of Bits skills must be installed. If any are missing, tell the user to install them:

```
/plugin install trailofbits/skills/plugins/entry-point-analyzer
/plugin install trailofbits/skills/plugins/audit-context-building
/plugin install trailofbits/skills/plugins/building-secure-contracts
/plugin install trailofbits/skills/plugins/property-based-testing
/plugin install trailofbits/skills/plugins/static-analysis
/plugin install trailofbits/skills/plugins/differential-review
/plugin install trailofbits/skills/plugins/supply-chain-risk-auditor
/plugin install trailofbits/skills/plugins/spec-to-code-compliance
/plugin install trailofbits/skills/plugins/variant-analysis
```

If any prerequisite is missing, inform the user and stop.

---

## Stage 1: Threat Modeling

Identify what can go wrong from an attacker's perspective.

1. **Run `entry-point-analyzer`** on the project.
   Save output to `sdl-output/entry-points.md`.

2. **Run `supply-chain-risk-auditor`** to check external dependencies (OpenZeppelin, Chainlink, etc.) for known vulnerabilities.

3. For each function classified as `Public (Unrestricted)` or `Review Required` by the entry-point-analyzer, **run `audit-context-building`** to perform deep analysis:
   - Block-by-block code analysis
   - Invariant identification
   - Trust boundary mapping
   - Cross-function dependency tracking

4. **Run `variant-analysis`** to search for known vulnerability patterns across the codebase.

5. **Apply STRIDE-Web3 checklist** to each entry point:

   - **Spoofing**: ecrecover verification, Oracle data validation, msg.sender vs tx.origin, cross-chain message auth
   - **Tampering**: Reentrancy (CEI pattern), integer overflow, storage collision, delegatecall, state variable access control
   - **Info Disclosure**: Private key management, MEV/mempool exposure, on-chain data visibility
   - **DoS**: Unbounded loops, block gas limit, revert attacks, emergency pause mechanism
   - **Elevation of Privilege**: Access control modifiers, multisig, proxy upgrade timelock, function visibility

6. **Identify composite threats**: Flash loan + oracle manipulation, MEV attacks, governance attacks, hook/callback attacks.

7. **Compile Threat Model** and save to `sdl-output/threat-model.md` with:
   - System overview and external dependencies
   - Asset inventory (what needs protecting, per layer)
   - Entry points table (from entry-point-analyzer)
   - STRIDE-Web3 threat list with IDs, categories, affected assets/functions
   - Composite threat scenarios

---

## Stage 2: Risk Assessment

Prioritize the threats identified in Stage 1.

For each threat in the threat model:

1. **Classify Impact** using Immunefi Vulnerability Severity Classification System v2.3:
   - **Critical**: Direct theft of user funds, permanent freezing, governance manipulation
   - **High**: Unclaimed yield theft, temporary freezing, temporary transfer blocking
   - **Medium**: Gas exhaustion DoS, griefing, contract unable to operate
   - **Low**: Below promised yield, function incorrect but no loss

2. **Estimate Likelihood**:
   - **High**: Known pattern, low cost, public exploit exists
   - **Medium**: Specific conditions required, moderate complexity
   - **Low**: Theoretical only, exceptional circumstances needed

3. **Apply correction factors**:
   - Higher TVL → increase severity
   - No proxy/upgrade → increase severity (immutable code)
   - Emergency pause available → decrease likelihood
   - Oracle/bridge dependency → increase likelihood

4. **Assign response strategy (4T)**:
   - **Transfer**: Bug bounty, insurance
   - **Avoid**: Remove or simplify risky functionality
   - **Accept**: Document as known risk
   - **Reduce**: Strengthen controls (code fix, additional testing)
   - Rule: Critical impact threats MUST be Reduce.

5. **Save** to `sdl-output/risk-register.md` with:
   - Summary counts (Critical/High/Medium/Low)
   - Full risk register table (ID, threat, impact, likelihood, score, response, action)
   - Correction factors applied

---

## Stage 3: Testing & Verification

Generate and run tests for all threats with Response = "Reduce" from Stage 2.

1. **Extract Reduce targets** from the risk register.

2. **Generate invariants** for each Reduce target, in priority order:
   - Fund conservation: `sum(deposits) == sum(withdrawals) + pool_balance`
   - Collateral ratios: `collateral > 0 || debt == 0`
   - Access control: admin functions revert without proper role
   - Price sanity: `oracle_price within ±X% of reference`

3. **Run `property-based-testing`** skill to convert invariants into property-based tests using Foundry/Echidna/Medusa.

4. **Run `spec-to-code-compliance`** to verify code matches its specification. This is critical for catching logic omissions (e.g., missing multiplication in price calculations).

5. **Run `static-analysis`** skill (Slither + CodeQL + Semgrep). Save SARIF output for GitHub integration.

6. **Generate Foundry test files** in `test/sdl/`:
   - `Invariants.t.sol` — invariant tests for Critical/High threats
   - `FuzzTests.t.sol` — fuzz tests for state-changing functions
   - `SanityChecks.t.sol` — oracle bounds, basic sanity checks

7. **Run tests and collect results**:
   ```bash
   forge test --gas-report > sdl-output/test-results.txt
   forge coverage > sdl-output/coverage-report.txt
   ```

8. **Verify coverage targets**: Line ≥ 90%, Branch ≥ 80%, Function = 100%.

9. **Save** test specification to `sdl-output/test-spec.md` with:
   - Reduce targets table
   - Invariant list with expressions
   - Spec compliance results
   - Static analysis summary
   - Coverage report

---

## Stage 4: Audit Preparation

Compile all SDL outputs into audit-ready documentation.

1. **Run `building-secure-contracts` audit-prep-assistant** skill:
   - Define security objectives
   - Run Slither, triage and fix easy issues
   - Remove dead code, unused libraries
   - Generate architecture docs, sequence diagrams, actor/privilege mappings
   - Freeze stable version

2. **Compile audit package** from all previous stages:
   - Threat Model (Stage 1)
   - Risk Register (Stage 2)
   - Test Specification + results (Stage 3)
   - Known Issues = Accept items from risk register
   - audit-prep-assistant deliverables

3. **Save** to `sdl-output/audit-preparation.md` with:
   - Project overview
   - SDL process summary (threat count, risk breakdown, coverage %)
   - Recommended audit focus areas (Critical/High threats)
   - Known issues table with acceptance rationale
   - List of all attached documents

---

## CI/CD Mode

When triggered by a PR (via GitHub Actions or pre-push hook):

1. **Run `differential-review`** on the changed files for security-focused diff analysis.
2. Execute Stages 1-3 scoped to changed contracts only.
3. Post summary as PR comment.
4. **Block PR** if:
   - Any Critical/High invariant test fails
   - Coverage drops below threshold
   - New Critical threat without Reduce strategy
   - Unresolved high-severity Slither finding
