#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd confindr.py
corrected="${OUTPUT_DIR}/04_corrected_reads"; out="${OUTPUT_DIR}/05_confindr"
mkdir -p "$out"

while IFS= read -r -d '' original_r1; do
    sample="$(sample_from_r1 "$original_r1")"; sample_dir="${out}/${sample}"
    [[ -s "${sample_dir}/confindr_report.csv" ]] && continue
    mkdir -p "$sample_dir/input"
    ln -sf "${corrected}/${sample}_1.corrected.fastq.gz" "${sample_dir}/input/${sample}_1.fastq.gz"
    ln -sf "${corrected}/${sample}_2.corrected.fastq.gz" "${sample_dir}/input/${sample}_2.fastq.gz"
    msg "ConFindr: $sample"
    confindr.py -i "${sample_dir}/input" -o "$sample_dir" -d "$CONFINDR_DB" \
        -t "$THREADS" -bf 0.025 -b 2 --cross_detail -Xmx 1500m -fid _1 -rid _2
done < <(list_r1_files)

