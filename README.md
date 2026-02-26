# Web3 SDL Skill

A Claude Code skill that automates the Security Development Lifecycle for smart contract projects, orchestrating [Trail of Bits](https://github.com/trailofbits/skills) security skills.

## Overview

4-stage SDL framework adapted from [Microsoft SDL](https://www.microsoft.com/en-us/securityengineering/sdl) for Web3:

| Stage | Goal | Output | Trail of Bits Skills |
|-------|------|--------|---------------------|
| 1. Threat Modeling | Identify threats | `threat-model.md` | entry-point-analyzer, audit-context-building, supply-chain-risk-auditor, variant-analysis |
| 2. Risk Assessment | Prioritize risks | `risk-register.md` | — (Immunefi v2.3 + STRIDE) |
| 3. Testing | Verify mitigations | `test-spec.md` + tests | property-based-testing, spec-to-code-compliance, static-analysis |
| 4. Audit Preparation | Compile docs | `audit-preparation.md` | building-secure-contracts |

CI/CD: **differential-review** for PR security analysis.

## Install

```bash
# 1. Install Trail of Bits skills (required)
/plugin install trailofbits/skills/plugins/entry-point-analyzer
/plugin install trailofbits/skills/plugins/audit-context-building
/plugin install trailofbits/skills/plugins/building-secure-contracts
/plugin install trailofbits/skills/plugins/property-based-testing
/plugin install trailofbits/skills/plugins/static-analysis
/plugin install trailofbits/skills/plugins/differential-review
/plugin install trailofbits/skills/plugins/supply-chain-risk-auditor
/plugin install trailofbits/skills/plugins/spec-to-code-compliance
/plugin install trailofbits/skills/plugins/variant-analysis

# 2. Install Slither
pip install slither-analyzer

# 3. (Optional) Add Slither-MCP for enhanced analysis
claude mcp add --transport stdio slither -- uvx --from git+https://github.com/trailofbits/slither-mcp slither-mcp

# 4. Add this skill to your project
cp -r web3-sdl-skill/ .claude/skills/web3-sdl/
```

## Usage

```bash
# Full SDL analysis
claude "Run the Web3 SDL skill on this project"

# Single stage
claude "Run SDL Stage 1 (Threat Modeling) on src/LendingPool.sol"

# CI mode on PR changes
claude "Run SDL in CI mode on the changed contracts"
```

## GitHub Actions

```yaml
# .github/workflows/sdl.yml
name: Web3 SDL Check
on:
  pull_request:
    paths: ['src/**/*.sol', 'contracts/**/*.sol']
jobs:
  sdl:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: foundry-rs/foundry-toolchain@v1
      - run: pip install slither-analyzer
      - uses: anthropics/claude-code-action@v1
        with:
          prompt: "Run the Web3 SDL skill on changed contracts. Post results as PR comment."
          allowed_tools: "Bash,Read,Write,Glob,Grep"
```

## Output

```
sdl-output/
├── threat-model.md       # Identified threats with STRIDE classification
├── entry-points.md       # Entry point analysis (Trail of Bits)
├── risk-register.md      # Prioritized risks with response strategies
├── test-spec.md          # Test specifications and invariants
├── test-results.txt      # Forge test output
├── coverage-report.txt   # Coverage report
├── slither-report.json   # Static analysis results
└── audit-preparation.md  # Compiled audit package
```

## Requirements

- [Foundry](https://book.getfoundry.sh/)
- [Claude Code](https://claude.ai/code)
- [Slither](https://github.com/crytic/slither)

## References

- [Microsoft SDL](https://www.microsoft.com/en-us/securityengineering/sdl/practices)
- [STRIDE for Blockchain](https://arxiv.org/pdf/2304.06725)
- [Immunefi Severity Classification v2.3](https://immunefi.com/immunefi-vulnerability-severity-classification-system-v2-3/)
- [Trail of Bits - Building Secure Contracts](https://github.com/crytic/building-secure-contracts)
- [Slither-MCP](https://blog.trailofbits.com/2025/11/15/level-up-your-solidity-llm-tooling-with-slither-mcp/)

## License

MIT
