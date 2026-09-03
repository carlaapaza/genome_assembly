#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
for p in kat jq mash lighter; do require_cmd "$p"; done
trimmed="${OUTPUT_DIR}/02_trimmed_reads"; out="${OUTPUT_DIR}/04_corrected_reads"
stats="${OUTPUT_DIR}/metrics/genome_size.tsv"
mkdir -p "$out" "${OUTPUT_DIR}/metrics" "${OUTPUT_DIR}/logs/correction"
printf 'sample\testimated_genome_size_bp\tkmer_min_copy\n' > "$stats"

while IFS= read -r -d '' r1; do
    sample="$(sample_from_r1 "$r1")"
    t1="${trimmed}/${sample}_1.trimmed.fastq.gz"; t2="${trimmed}/${sample}_2.trimmed.fastq.gz"
    [[ -s "$t1" && -s "$t2" ]] || die "Trimmed pair missing for $sample"
    work="${OUTPUT_DIR}/work/04_correction/${sample}"; mkdir -p "$work"
    kat hist --mer_len 21 --thread 1 --output_prefix "${work}/${sample}" "$t1" >/dev/null
    minima="$(jq -r '.global_minima.freq' "${work}/${sample}.dist_analysis.json")"
    mash sketch -o "${work}/${sample}" -k 32 -m "$minima" -r "$t1" 2> "${work}/mash_stats.txt"
    genome_size="$(awk -F': ' '/Estimated genome size:/{printf "%.0f",$2; exit}' "${work}/mash_stats.txt")"
    [[ "$genome_size" =~ ^[0-9]+$ ]] || die "Mash could not estimate genome size for $sample"
    printf '%s\t%s\t%s\n' "$sample" "$genome_size" "$minima" >> "$stats"

    [[ -s "${out}/${sample}_1.corrected.fastq.gz" && -s "${out}/${sample}_2.corrected.fastq.gz" ]] && continue
    rm -rf "${work}/lighter"
    run_logged "${OUTPUT_DIR}/logs/correction/${sample}.log" \
        lighter -od "${work}/lighter" -r "$t1" -r "$t2" -K 32 "$genome_size" -maxcor 1 -t "$THREADS"
    cor=("${work}/lighter"/*.cor.fq.gz)
    (( ${#cor[@]} == 2 )) || die "Lighter did not create two corrected files for $sample"
    mv "${cor[0]}" "${out}/${sample}_1.corrected.fastq.gz"
    mv "${cor[1]}" "${out}/${sample}_2.corrected.fastq.gz"
done < <(list_r1_files)
