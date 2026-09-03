#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd bactinspector
trimmed="${OUTPUT_DIR}/02_trimmed_reads"; out="${OUTPUT_DIR}/10_species_id"
mkdir -p "$out"
while IFS= read -r -d '' original_r1; do
    sample="$(sample_from_r1 "$original_r1")"; sample_out="${out}/${sample}"
    mkdir -p "$sample_out"
    (cd "$sample_out" && bactinspector check_species -fq "${trimmed}/${sample}_1.trimmed.fastq.gz")
done < <(list_r1_files)

