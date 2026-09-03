#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd spades.py
merged="${OUTPUT_DIR}/07_merged_reads"; out="${OUTPUT_DIR}/08_spades"
mkdir -p "$out" "${OUTPUT_DIR}/logs/spades"
careful=(); [[ "$SPADES_CAREFUL" == "true" ]] && careful=(--careful)

while IFS= read -r -d '' original_r1; do
    sample="$(sample_from_r1 "$original_r1")"; source_dir="${merged}/${sample}"; sample_out="${out}/${sample}"
    [[ -s "${sample_out}/scaffolds.fasta" ]] && continue
    r1="${source_dir}/${sample}.notCombined_1.fastq.gz"; r2="${source_dir}/${sample}.notCombined_2.fastq.gz"
    joined="${source_dir}/${sample}.extendedFrags.fastq.gz"
    [[ -s "$r1" && -s "$r2" && -s "$joined" ]] || die "FLASH output missing for $sample"
    read_length="$(gzip -cd "$r1" | awk 'NR==2{print length($0);exit}')"
    if (( read_length < 75 )); then kmers="21,33,43,53";
    elif (( read_length < 150 )); then kmers="21,33,43,53,63,75";
    else kmers="21,33,43,55,77,99"; fi
    msg "SPAdes: $sample; kmers=$kmers"
    run_logged "${OUTPUT_DIR}/logs/spades/${sample}.log" \
        spades.py --pe1-1 "$r1" --pe1-2 "$r2" --pe1-m "$joined" --only-assembler \
        "${careful[@]}" -k "$kmers" --threads "$THREADS" --memory "$SPADES_MEMORY_GB" -o "$sample_out"
done < <(list_r1_files)

