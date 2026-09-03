#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd fastqc; require_cmd multiqc
trimmed="${OUTPUT_DIR}/02_trimmed_reads"; out="${OUTPUT_DIR}/03_fastqc_trimmed"
mkdir -p "$out/reports" "$out/multiqc"
reads=()
while IFS= read -r -d '' file; do reads+=("$file"); done \
    < <(find "$trimmed" -maxdepth 1 -type f -name '*.trimmed.fastq.gz' -print0 | sort -z)
(( ${#reads[@]} > 0 )) || die "No trimmed reads found"
fastqc --threads "$THREADS" --extract --outdir "$out/reports" "${reads[@]}"
multiqc "$out/reports" --outdir "$out/multiqc" --filename multiqc_report.html --force
