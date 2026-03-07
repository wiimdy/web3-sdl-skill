#!/usr/bin/env bash

set -euo pipefail

INPUT_PATH="${1:-}"
OUTPUT_PATH="${2:-}"
PDF_ENGINE="${3:-${PDF_ENGINE:-}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAINTEXT_RENDERER="${SCRIPT_DIR}/render_plaintext_pdf.py"
REPORT_TEMPLATE="${SCRIPT_DIR}/../assets/templates/pandoc-report-template.tex"
HTML_BUILDER="${SCRIPT_DIR}/build_report_html.py"
BROWSER_RENDERER="${SCRIPT_DIR}/render_report_browser.cjs"
RENDERER_ROOT="${SCRIPT_DIR}/../.report-renderer"

if [[ -z "${INPUT_PATH}" || -z "${OUTPUT_PATH}" ]]; then
  echo "Usage: render_final_report.sh <input-markdown> <output-pdf> [pdf-engine]" >&2
  exit 1
fi

if [[ ! -f "${INPUT_PATH}" ]]; then
  echo "Input markdown file not found: ${INPUT_PATH}" >&2
  exit 1
fi

OUTPUT_DIR="$(dirname "${OUTPUT_PATH}")"
mkdir -p "${OUTPUT_DIR}"

try_pandoc() {
  local engine="$1"
  local template_path="${2:-}"
  local log_file
  log_file="$(mktemp)"

  if ! command -v pandoc >/dev/null 2>&1; then
    rm -f "${log_file}"
    return 1
  fi

  local args=(
    "${INPUT_PATH}"
    "--from=markdown"
    "--to=pdf"
    "--output=${OUTPUT_PATH}"
  )

  if [[ -n "${engine}" ]]; then
    args+=("--pdf-engine=${engine}")
  fi

  if [[ -n "${template_path}" ]]; then
    args+=("--template=${template_path}")
  fi

  if pandoc "${args[@]}" >"${log_file}" 2>&1; then
    rm -f "${log_file}"
    return 0
  fi

  if [[ "${RENDER_VERBOSE:-0}" == "1" ]]; then
    cat "${log_file}" >&2
  else
    if [[ -n "${engine}" ]]; then
      if [[ -n "${template_path}" ]]; then
        echo "Pandoc PDF render failed with engine '${engine}' and custom template. Trying the next renderer." >&2
      else
        echo "Pandoc PDF render failed with engine '${engine}'. Trying the next renderer." >&2
      fi
    else
      echo "Pandoc PDF render failed with the default engine. Trying the next renderer." >&2
    fi
  fi
  rm -f "${log_file}"
  return 1
}

render_plaintext_fallback() {
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required for the plain-text PDF fallback renderer." >&2
    exit 1
  fi

  python3 "${PLAINTEXT_RENDERER}" "${INPUT_PATH}" "${OUTPUT_PATH}"
  echo "Rendered ${OUTPUT_PATH} with the plain-text PDF fallback renderer." >&2
}

try_browser_render() {
  local tmp_dir
  local cover_html
  local body_html
  local cover_pdf
  local body_pdf

  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/web3-sdl-report.XXXXXX")"
  cover_html="${tmp_dir}/cover.html"
  body_html="${tmp_dir}/body.html"
  cover_pdf="${tmp_dir}/cover.pdf"
  body_pdf="${tmp_dir}/body.pdf"

  if ! command -v python3 >/dev/null 2>&1; then
    rm -rf "${tmp_dir}"
    return 1
  fi

  if ! command -v node >/dev/null 2>&1; then
    rm -rf "${tmp_dir}"
    return 1
  fi

  if [[ ! -f "${RENDERER_ROOT}/package.json" ]] || [[ ! -d "${RENDERER_ROOT}/node_modules/playwright" ]]; then
    rm -rf "${tmp_dir}"
    return 1
  fi

  if ! command -v pdfunite >/dev/null 2>&1; then
    rm -rf "${tmp_dir}"
    return 1
  fi

  python3 "${HTML_BUILDER}" "${INPUT_PATH}" "${cover_html}" cover
  python3 "${HTML_BUILDER}" "${INPUT_PATH}" "${body_html}" body
  node "${BROWSER_RENDERER}" "${cover_html}" "${cover_pdf}"
  node "${BROWSER_RENDERER}" "${body_html}" "${body_pdf}"
  pdfunite "${cover_pdf}" "${body_pdf}" "${OUTPUT_PATH}"
  rm -rf "${tmp_dir}"
}

if try_browser_render; then
  exit 0
fi

if [[ -f "${REPORT_TEMPLATE}" ]]; then
  if [[ -n "${PDF_ENGINE}" ]] && try_pandoc "${PDF_ENGINE}" "${REPORT_TEMPLATE}"; then
    exit 0
  fi

  for engine in tectonic pdflatex lualatex; do
    if command -v "${engine}" >/dev/null 2>&1 && try_pandoc "${engine}" "${REPORT_TEMPLATE}"; then
      exit 0
    fi
  done
fi

if [[ -n "${PDF_ENGINE}" ]] && try_pandoc "${PDF_ENGINE}"; then
  exit 0
fi

for engine in wkhtmltopdf weasyprint prince tectonic xelatex lualatex pdflatex; do
  if command -v "${engine}" >/dev/null 2>&1 && try_pandoc "${engine}"; then
    exit 0
  fi
done

render_plaintext_fallback
