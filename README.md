# Web3 SDL Workflows

`web3-sdl-workflows` is a modular Claude Code skill for smart-contract SDL.
It supports:

- `project-sdl`: baseline SDL for the whole repository
- `diff-sdl`: change-focused SDL driven by `git log`, `git diff`, tests, and
  semantic validation

Use `diff-sdl` when you care about a branch, PR, commit range, changed oracle
surface, or audit-style regression review. Use `project-sdl` when you need a
baseline threat model and broader repository SDL.

## Install In Claude Code

Recommended project-local install:

```bash
mkdir -p ./.claude/skills
git clone https://github.com/wiimdy/web3-sdl-skill.git \
  ./.claude/skills/web3-sdl-workflows
```

This keeps the skill inside the current repository at
`./.claude/skills/web3-sdl-workflows`.

If you already have a local checkout elsewhere, run the installer from your
project root:

```bash
/path/to/web3-sdl-skill/scripts/install_claude_code.sh
```

By default the installer writes to `./.claude/skills/web3-sdl-workflows`.

After that, Claude Code can trigger the skill when your prompt matches
[`SKILL.md`](./SKILL.md).

## Quick Start

Minimum install:

- Claude Code
- Git
- Foundry (`forge`)
- Python 3

Recommended install:

- Node.js with `npm` / `npx`
- `npm install --prefix ./.claude/skills/web3-sdl-workflows/.report-renderer`
- `npm exec --prefix ./.claude/skills/web3-sdl-workflows/.report-renderer playwright -- install chromium`

Important for strict `diff-sdl` runs:

- Provide the repository's required RPC env vars before Stage 3 when proposal,
  fork, oracle, or integration checks need live chain state.
- Keep `runtime_validation.block_on_missing_rpc_for_required_checks: true` if
  missing RPC should block completion instead of being treated as a soft skip.

Optional install:

- `./.claude/skills/web3-sdl-workflows/scripts/install_claude_code.sh --install-tob-skills`
- `./.claude/skills/web3-sdl-workflows/scripts/install_claude_code.sh --install-solidity-auditor`
- macOS Pandoc fallback: `brew install pandoc tectonic`


## Typical Usage

### In Claude Code

Run these from the target repository root. Each command below is self-contained.

Run skill in full `project-sdl` mode:

```bash
claude "Run the Web3 SDL skill on this project in project-sdl mode. Complete Stages 1 through 4 and produce the SDL artifacts."
```

Run skill in full `diff-sdl` mode:

```bash
claude "Run the Web3 SDL skill on this branch in diff-sdl mode. Complete Stages 1 through 4, run the required integration, fuzz, invariant, and semantic checks, and produce the SDL artifacts."
```

Run `diff-sdl` for a PR or commit range:

```bash
claude "Run the Web3 SDL skill in diff-sdl mode for this PR. Focus on changed oracle configs, STRIDE-Web3, privilege boundaries, and required integration, fuzz, invariant, and semantic checks."
```

Run only the early analysis stages:

```bash
claude "Run the Web3 SDL skill on this branch in diff-sdl mode. Execute only Stage 1 and Stage 2, then write the threat model and prioritized risk register."
```

Run only the reporting stage after evidence already exists:

```bash
claude "Run the Web3 SDL skill on this project in project-sdl mode. Use the existing findings and verification evidence, then execute only Stage 4 and write the final report."
```

## What This Skill Produces

`project-sdl` writes:

```text
sdl-output/project-sdl/
├── threat-model.md
├── risk-register.md
├── test-verification.md
├── final-report.md
└── final-report.pdf
```

`diff-sdl` writes:

```text
sdl-output/diff-sdl/
├── threat-model.md
├── change-threat-analysis.md
├── risk-register.md
├── test-verification.md
├── audit-preparation.md
├── final-report.md
└── final-report.pdf
```

The report is designed to look like an audit-firm deliverable:

- cover page
- table of contents
- findings overview
- detailed findings with severity and status badges
- verification matrix
- appendix and runtime notes

## Requirements

Required for the skill itself:

- Claude Code
- Git
- Foundry (`forge`)
- Python 3

Required for the best-looking PDF output:

- Node.js with `npm` / `npx`
- local browser renderer dependencies installed under
  `./.claude/skills/web3-sdl-workflows/.report-renderer/`
- Playwright Chromium browser

Optional:

- Pashov `solidity-auditor` command
- Trail of Bits Claude plugins for the full-rigor review path
- macOS Pandoc fallback: `brew install pandoc tectonic`

## Important: RPC Inputs For Stage 3

`diff-sdl` can discover likely runtime requirements, but it cannot fabricate RPC
access. If the changed surface depends on fork-backed proposal tests, live
oracle checks, or integration paths that need chain state, provide the required
RPC env vars before expecting a complete Stage 3 result.

Recommended strict behavior:

- keep `runtime_validation.allow_user_decline_runtime_checks: false`
- keep `runtime_validation.block_on_missing_rpc_for_required_checks: true`
- treat missing RPC as a blocker for completion, not as a harmless skip

Example Base mainnet RPC setup:

```bash
export BASE_RPC_URL="https://base-mainnet.g.alchemy.com/v2/<alchemy-api-key>"
```

Then point the config at that env name:

```yaml
runtime_validation:
  rpc_url_env: BASE_RPC_URL
```

The skill may still run Tier 3 semantic checks without RPC, but those checks are
supporting evidence only. They do not replace the required runtime-backed test
path when the config says RPC is mandatory.

## Install The Styled PDF Renderer

The default report renderer now uses browser-based HTML/CSS output, not LaTeX.
This gives better typography, better page breaks, cover pages, TOC, and more
predictable layout.

Install the local renderer once:

```bash
npm install --prefix ./.claude/skills/web3-sdl-workflows/.report-renderer
npm exec --prefix ./.claude/skills/web3-sdl-workflows/.report-renderer \
  playwright -- install chromium
```

What happens if you skip this:

- the script will try the browser renderer first
- if that is unavailable, it will fall back to the Pandoc path
- if that also fails, it will fall back to the plain-text PDF renderer

So the styled browser renderer is the recommended path.

If you also want a secondary non-browser PDF path on macOS:

```bash
brew install pandoc tectonic
```

`render_final_report.sh` will try `pandoc` with `tectonic` automatically when
the browser renderer is unavailable.

## Optional: Install Pashov Solidity Auditor

Use this when you want an extra scoped security-review pass over changed files
and nearby dependencies.

Installer script:

```bash
./.claude/skills/web3-sdl-workflows/scripts/install_claude_code.sh \
  --install-solidity-auditor
```

Manual upstream method:

```bash
tmp_dir="$(mktemp -d)"
mkdir -p ./.claude/commands
git clone https://github.com/pashov/skills.git "$tmp_dir/skills"
cp -R "$tmp_dir/skills/solidity-auditor" ./.claude/commands/solidity-auditor
rm -rf "$tmp_dir"
```

This makes the command invocable as `/solidity-auditor` inside Claude Code.

## Required: Trail Of Bits Skills For Full-Rigor Runs

The original monolithic SDL workflow relied on these Trail of Bits plugins:

```text
entry-point-analyzer@trailofbits
audit-context-building@trailofbits
building-secure-contracts@trailofbits
property-based-testing@trailofbits
differential-review@trailofbits
supply-chain-risk-auditor@trailofbits
spec-to-code-compliance@trailofbits
variant-analysis@trailofbits
```

Install them with:

```bash
./.claude/skills/web3-sdl-workflows/scripts/install_claude_code.sh \
  --install-tob-skills
```

Optional best-effort tools from the older workflow:

```text
static-analysis@trailofbits
slither
semgrep
codeql
echidna
medusa
```

## Suggested Claude Code Setup

Keep the local example config in [`sdl-config.yml`](./sdl-config.yml) and turn
on extra enrichment only after the companion tooling is installed.

Example:

```yaml
mode:
  default: diff-sdl
  allow_stage_selection: true

runtime_validation:
  enabled: true
  rpc_url_env: BASE_RPC_URL
  allow_user_decline_runtime_checks: false
  block_on_missing_rpc_for_required_checks: true

testing:
  require_integration: true
  require_fuzz: true
  require_invariants: true
  allow_skip: false

external_enrichment:
  enable_subagent_pass: true
  use_solidity_auditor: true
  candidate_keywords:
    - oracle
    - rounding
    - shares
    - liquidation
    - reentrancy

fp_control:
  second_pass_required: true
  min_disconfirming_checks_per_high_or_critical: 2

semantic_validation:
  oracle_semantic_correctness_required: true
  require_denomination_trace: true
  require_validate_gap_analysis: true
  max_relative_drift: 0.05

reporting:
  render_pdf: true
  pdf_fallback: plaintext
```


### Direct Helper Commands

Collect the changed scope:

```bash
./.claude/skills/web3-sdl-workflows/scripts/collect_change_scope.sh origin/main 20
```

Discover runtime requirements before Stage 3:

```bash
./.claude/skills/web3-sdl-workflows/scripts/discover_runtime_requirements.sh .
```

Run a deterministic oracle semantic check:

```bash
./.claude/skills/web3-sdl-workflows/scripts/check_oracle_semantics.sh \
  --address-book chains/8453.json \
  --asset cbETH \
  --selected-feed cbETHETH_ORACLE \
  --expected-feed cbETH_ORACLE \
  --consumer CHAINLINK_ORACLE \
  --market MOONWELL_cbETH \
  --rpc-url "$BASE_RPC_URL" \
  --max-relative-drift 0.05
```

Exit code meanings:

- `0`: selected feed matches the expected semantic path within threshold
- `2`: drift exceeded the allowed threshold
- non-zero other than `2`: setup or execution failure

Render the final report manually:

```bash
./.claude/skills/web3-sdl-workflows/scripts/render_final_report.sh \
  sdl-output/diff-sdl/final-report.md \
  sdl-output/diff-sdl/final-report.pdf
```

## Expected Result Quality

For a healthy `diff-sdl` run, expect:

- a compact but explicit threat model
- change-focused STRIDE-Web3 analysis
- risk register with severity and evidence
- test-verification tied to the changed surface
- a styled PDF report with cover page, TOC, and readable findings layout

For a strong oracle/config review, expect:

- denomination lineage
- expected-versus-observed checks
- canonical repo pattern comparison
- runtime evidence, not only liveness checks

## Verification Checklist

Check the environment:

```bash
forge --version
python3 --version
node --version
npm --version
claude plugin list
```

Check that the skill is installed:

```bash
ls ./.claude/skills/web3-sdl-workflows
```

Check that the styled PDF renderer is ready:

```bash
test -d ./.claude/skills/web3-sdl-workflows/.report-renderer/node_modules/playwright
(
  test -d "$HOME/Library/Caches/ms-playwright" ||
  test -d "$HOME/.cache/ms-playwright"
)
```

Check that the Trail of Bits plugins you expect are installed before relying on
the full-rigor path.

## Important Files

- Skill entrypoint: [`SKILL.md`](./SKILL.md)
- Config example: [`sdl-config.yml`](./sdl-config.yml)
- Diff workflow: [`references/diff-sdl.md`](./references/diff-sdl.md)
- Project workflow: [`references/project-sdl.md`](./references/project-sdl.md)
- Semantic checks: [`references/semantic-validation.md`](./references/semantic-validation.md)
- Testing rules: [`references/testing-requirements.md`](./references/testing-requirements.md)
- Report rules: [`references/reporting-requirements.md`](./references/reporting-requirements.md)
- Final report outline: [`assets/templates/final-report-outline.md`](./assets/templates/final-report-outline.md)

## Notes

- The browser renderer is now the preferred PDF path because it produces much
  better typography and layout than the plain fallback.
- The Pandoc and plain-text renderers still exist as backup paths.
- Findings only count as accepted SDL findings when local repository evidence
  supports them.
