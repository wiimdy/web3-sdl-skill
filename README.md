# Web3 SDL Skill

A Claude Code skill for security-focused SDL execution on smart contract projects.
It runs a 4-stage workflow with a simplified artifact set: one output per stage plus one final PDF.

## What This Skill Covers

- Stage 1: Threat modeling with STRIDE-Web3 and attack trees
- Diff-centered scope from recent current-branch commits (`git log` + `git diff`) as source-of-truth for new external touchpoints
- Stage 2: Risk scoring and response planning (4T)
- False-positive reduction with mandatory second-think pass for High/Critical risks
- Stage 3: Testing and verification for `Reduce` targets
- Stage 4: Audit preparation package
- Final: Stakeholder PDF report that consolidates all stages

## Prerequisites

Required:

- [Foundry](https://book.getfoundry.sh/)
- [Claude Code](https://claude.ai/code)
- [Slither](https://github.com/crytic/slither)
- Trail of Bits skills:

```bash
/plugin marketplace add trailofbits/skills
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

Optional (best-effort in the skill):

- `semgrep`
- `codeql`
- `echidna-test` and/or `medusa`
- `pandoc` (recommended for PDF export)

### Optional Tool Installation

#### `semgrep`

```bash
# macOS/Linux (Homebrew)
brew install semgrep

# fallback (pip)
python3 -m pip install semgrep

# verify
semgrep --version
```

#### `codeql`

Recommended: download the CodeQL bundle from GitHub releases and add it to `PATH`.

```bash
# 1) download from:
# https://github.com/github/codeql-action/releases

# 2) extract
tar -xzf codeql-bundle-*.tar.gz

# 3) add CLI to PATH (current shell)
export PATH="$PWD/codeql:$PATH"

# verify
codeql version
```

#### `echidna-test` / `echidna`

```bash
# macOS/Linux (Homebrew)
brew install echidna

# verify (skill checks echidna-test first)
echidna-test --version || echidna --version
```

#### `medusa`

```bash
# requires Go installed
go install github.com/crytic/medusa@latest

# ensure Go bin is on PATH if needed
export PATH="$(go env GOPATH)/bin:$PATH"

# verify
medusa --version
```

#### `pandoc`

```bash
# macOS/Linux (Homebrew)
brew install pandoc

# verify
pandoc --version
```

## Install Skill Into Project

```bash
mkdir -p .claude/skills/web3-sdl
cp -R web3-sdl-skill/. .claude/skills/web3-sdl/
```

## Configure (`sdl-config.yml`)

The skill reads `sdl-config.yml` at repo root if present.

Key sections:

- `project`: chain and optional TVL
- `diff_scope`: base ref, optional explicit range, commit window, and diff context controls
- `runtime_validation`: RPC env key and fork block controls
- `risk_scoring`: impact and likelihood mappings
- `coverage_gates`: minimum coverage thresholds
- `gating`: CI blocking conditions
- `fp_control`: second-think false-positive control and diff-to-test closure gates

Example file: [`sdl-config.yml`](./sdl-config.yml)

## How To Run

Full SDL run:

```bash
claude "Run the Web3 SDL skill on this project /web3-sdl"
```

CI/PR scoped run:

```bash
claude "Run SDL in CI mode on changed contracts"
```

Targeted run (example):

```bash
claude "Run Stage 1 and Stage 2 of Web3 SDL for this repo"
```

## What Outputs You Get

All artifacts are written to `sdl-output/`.

| File | Purpose |
|---|---|
| `threat-model.md` | Stage 1 threat model with branch history, diff hunk mapping, recent-commit-based external touchpoint delta, STRIDE, DFD, and attack trees |
| `risk-register.md` | Stage 2 risk scoring plus first-pass vs second-pass false-positive disposition |
| `test-verification.md` | Stage 3 verification outcomes with diff-to-test closure and coverage status |
| `audit-preparation.md` | Stage 4 audit package summary including false-positive and closure summaries |
| `final-report.pdf` | Final stakeholder-ready report consolidating all stages |

## How To Read Results Quickly

1. Start with `sdl-output/final-report.pdf` for stakeholder summary.
2. Use `sdl-output/risk-register.md` for priority and response decisions.
3. Use `sdl-output/test-verification.md` for validation evidence and coverage gates.
4. Check `sdl-output/audit-preparation.md` for next audit actions.

## CI/CD Notes

In CI mode, the skill should:

- resolve current-branch commit window (`git log --first-parent`) and analyzed diff range
- detect changed Solidity files
- derive new external touchpoint decisions from recent commit evidence (not untouched historical code)
- run differential analysis and embed it in `threat-model.md`
- scope analysis to changed contracts and close dependencies
- enforce second-think pass for High/Critical and P0/P1 items
- enforce diff-to-test mapping for changed state-modifying functions
- produce the same 5 artifacts listed above
- fail the job on configured gating conditions

## References

- [Microsoft SDL](https://www.microsoft.com/en-us/securityengineering/sdl/practices)
- [STRIDE for Blockchain](https://arxiv.org/pdf/2304.06725)
- [Immunefi Severity Classification v2.3](https://immunefi.com/immunefi-vulnerability-severity-classification-system-v2-3/)
- [Trail of Bits - Building Secure Contracts](https://github.com/crytic/building-secure-contracts)
- [Trail of Bits Skills](https://github.com/trailofbits/skills)

## License

MIT
