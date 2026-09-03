#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd fastqc; require_cmd multiqc; assert_inputs

out="${OUTPUT_DIR}/01_fastqc_raw"
mkdir -p "$out/reports" "$out/multiqc"
reads=()
while IFS= read -r -d '' file; do reads+=("$file"); done \
    < <(find "$INPUT_DIR" -maxdepth 1 -type f \( -name "*${R1_SUFFIX}" -o -name "*${R2_SUFFIX}" \) -print0 | sort -z)
msg "FastQC before trimming: ${#reads[@]} files"
fastqc --threads "$THREADS" --outdir "$out/reports" "${reads[@]}"
multiqc "$out/reports" --outdir "$out/multiqc" --filename multiqc_report.html --force
