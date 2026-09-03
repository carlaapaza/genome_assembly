#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd flash
reads="${OUTPUT_DIR}/06_downsampled_reads"; out="${OUTPUT_DIR}/07_merged_reads"
mkdir -p "$out" "${OUTPUT_DIR}/logs/flash"
while IFS= read -r -d '' original_r1; do
    sample="$(sample_from_r1 "$original_r1")"; sample_out="${out}/${sample}"
    [[ -s "${sample_out}/${sample}.extendedFrags.fastq.gz" ]] && continue
    mkdir -p "$sample_out"
    run_logged "${OUTPUT_DIR}/logs/flash/${sample}.log" \
        flash -m 20 -M 100 -t "$THREADS" -d "$sample_out" -o "$sample" -z \
        "${reads}/${sample}_1.downsampled.fastq.gz" "${reads}/${sample}_2.downsampled.fastq.gz"
done < <(list_r1_files)

