#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd python
spades="${OUTPUT_DIR}/08_spades"; out="${OUTPUT_DIR}/09_assemblies"
mkdir -p "$out"
while IFS= read -r -d '' original_r1; do
    sample="$(sample_from_r1 "$original_r1")"; input="${spades}/${sample}/scaffolds.fasta"; output="${out}/${sample}.fasta"
    [[ -s "$input" ]] || die "SPAdes assembly missing for $sample"
    python "${PROJECT_DIR}/tools/filter_spades_fasta.py" -i "$input" -o "$output" \
        --min-length "$MIN_CONTIG_LENGTH" --min-coverage "$MIN_CONTIG_COVERAGE"
done < <(list_r1_files)

