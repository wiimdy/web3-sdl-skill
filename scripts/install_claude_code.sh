#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CLAUDE_HOME="${CLAUDE_HOME:-${HOME}/.claude}"
INSTALL_SOLIDITY_AUDITOR="false"
INSTALL_TOB_SKILLS="false"
PASHOV_REPO_DIR=""
TOB_PLUGIN_SCOPE="user"
TOB_REQUIRED_PLUGINS=(
  "entry-point-analyzer"
  "audit-context-building"
  "building-secure-contracts"
  "property-based-testing"
  "differential-review"
  "supply-chain-risk-auditor"
  "spec-to-code-compliance"
  "variant-analysis"
)

usage() {
  cat <<'EOF'
Usage: install_claude_code.sh [options]

Install the web3-sdl-workflows skill into Claude Code and optionally install:
- the Pashov solidity-auditor command
- the required Trail of Bits plugins for the full-rigor SDL workflow

Options:
  --claude-home PATH              Override the Claude Code home directory.
  --install-solidity-auditor      Install the Pashov solidity-auditor command.
  --install-tob-skills            Install and enable required Trail of Bits plugins.
  --pashov-repo-dir PATH          Use an existing local clone of pashov/skills.
  -h, --help                      Show this help message.

Environment variables:
  CLAUDE_HOME                     Same as --claude-home
EOF
}

require_cmd() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required command: ${command_name}" >&2
    exit 1
  fi
}

install_main_skill() {
  local target_dir="${CLAUDE_HOME}/skills/web3-sdl-workflows"

  mkdir -p "${CLAUDE_HOME}/skills"
  rm -rf "${target_dir}"
  cp -R "${SKILL_ROOT}" "${target_dir}"

  echo "Installed web3-sdl-workflows to ${target_dir}"
}

install_solidity_auditor() {
  local source_dir=""
  local temp_dir=""
  local target_dir="${CLAUDE_HOME}/commands/solidity-auditor"

  require_cmd git

  if [[ -n "${PASHOV_REPO_DIR}" ]]; then
    source_dir="${PASHOV_REPO_DIR}/solidity-auditor"
  else
    temp_dir="$(mktemp -d)"
    git clone --depth 1 https://github.com/pashov/skills.git "${temp_dir}/skills" >/dev/null 2>&1
    source_dir="${temp_dir}/skills/solidity-auditor"
  fi

  if [[ ! -d "${source_dir}" ]]; then
    echo "Unable to find solidity-auditor at ${source_dir}" >&2
    rm -rf "${temp_dir}"
    exit 1
  fi

  mkdir -p "${CLAUDE_HOME}/commands"
  rm -rf "${target_dir}"
  cp -R "${source_dir}" "${target_dir}"
  rm -rf "${temp_dir}"

  echo "Installed solidity-auditor to ${target_dir}"
}

get_plugin_status() {
  local plugin_id="$1"

  claude plugin list | awk -v plugin="${plugin_id}" '
    index($0, plugin) { found=1; next }
    found && /Status:/ {
      if ($0 ~ /enabled/) {
        print "enabled"
      } else if ($0 ~ /disabled/) {
        print "disabled"
      }
      exit
    }
  '
}

ensure_tob_marketplace() {
  require_cmd claude

  if claude plugin marketplace list | grep -Fq "GitHub (trailofbits/skills)"; then
    echo "Trail of Bits marketplace already configured"
    return
  fi

  claude plugin marketplace add trailofbits/skills >/dev/null
  echo "Added Trail of Bits marketplace"
}

install_tob_plugin() {
  local plugin_name="$1"
  local plugin_id="${plugin_name}@trailofbits"
  local plugin_status=""

  plugin_status="$(get_plugin_status "${plugin_id}")"

  if [[ -z "${plugin_status}" ]]; then
    claude plugin install "${plugin_id}" --scope "${TOB_PLUGIN_SCOPE}" >/dev/null
    echo "Installed ${plugin_id}"
    plugin_status="$(get_plugin_status "${plugin_id}")"
  else
    echo "Plugin already installed: ${plugin_id}"
  fi

  if [[ "${plugin_status}" == "disabled" ]]; then
    claude plugin enable "${plugin_id}" --scope "${TOB_PLUGIN_SCOPE}" >/dev/null
    echo "Enabled ${plugin_id}"
  elif [[ "${plugin_status}" == "enabled" ]]; then
    echo "Plugin already enabled: ${plugin_id}"
  else
    echo "Unable to determine plugin status for ${plugin_id}" >&2
    exit 1
  fi
}

install_tob_skills() {
  local plugin_name=""

  ensure_tob_marketplace

  for plugin_name in "${TOB_REQUIRED_PLUGINS[@]}"; do
    install_tob_plugin "${plugin_name}"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude-home)
      CLAUDE_HOME="$2"
      shift 2
      ;;
    --install-solidity-auditor)
      INSTALL_SOLIDITY_AUDITOR="true"
      shift
      ;;
    --install-tob-skills)
      INSTALL_TOB_SKILLS="true"
      shift
      ;;
    --pashov-repo-dir)
      PASHOV_REPO_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

install_main_skill

if [[ "${INSTALL_SOLIDITY_AUDITOR}" == "true" ]]; then
  install_solidity_auditor
fi

if [[ "${INSTALL_TOB_SKILLS}" == "true" ]]; then
  install_tob_skills
fi

echo "Done."
