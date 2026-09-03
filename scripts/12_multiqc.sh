#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd multiqc
out="${OUTPUT_DIR}/12_quality_reports"; mkdir -p "$out"
multiqc "$OUTPUT_DIR" --outdir "$out" --filename assembly_multiqc_report.html --force --interactive

