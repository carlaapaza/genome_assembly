#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd qualifyr
conditions="${PROJECT_DIR}/config/qc_conditions.yml"
assemblies="${OUTPUT_DIR}/09_assemblies"; out="${OUTPUT_DIR}/13_qualifyr"
mkdir -p "$out/json" "$out/pass" "$out/warning" "$out/failure" "$out/file_size"

while IFS= read -r -d '' original_r1; do
    sample="$(sample_from_r1 "$original_r1")"
    r1_summary="${OUTPUT_DIR}/03_fastqc_trimmed/reports/${sample}_1.trimmed_fastqc/summary.txt"
    r2_summary="${OUTPUT_DIR}/03_fastqc_trimmed/reports/${sample}_2.trimmed_fastqc/summary.txt"
    confindr="${OUTPUT_DIR}/05_confindr/${sample}/confindr_report.csv"
    quast="${OUTPUT_DIR}/11_quast/per_sample/${sample}/report.tsv"
    assembly="${assemblies}/${sample}.fasta"
    species="$(find "${OUTPUT_DIR}/10_species_id/${sample}" -type f -name 'species_investigation*.tsv' -print -quit)"
    for required in "$r1_summary" "$r2_summary" "$confindr" "$quast" "$assembly" "$species"; do
        [[ -s "$required" ]] || die "QualiFyr input missing for $sample: $required"
    done
    size_mb="$(stat -f '%z' "$original_r1" 2>/dev/null || stat -c '%s' "$original_r1")"
    size_mb="$(awk -v b="$size_mb" 'BEGIN{printf "%.3f",b/1000000}')"
    size_file="${out}/file_size/${sample}.tsv"
    printf 'file\tsize\n%s\t%s\n' "$sample" "$size_mb" > "$size_file"

    msg "QualiFyr: $sample"
    status="$(qualifyr check -y "$conditions" -f "$r1_summary" "$r2_summary" \
        -c "$confindr" -q "$quast" -b "$species" -z "$size_file" -s "$sample")"
    case "$status" in
        PASS) level="pass" ;;
        WARNING) level="warning" ;;
        FAILURE) level="failure" ;;
        *) die "Unexpected QualiFyr status for $sample: $status" ;;
    esac
    cp "$assembly" "${out}/${level}/"
    (cd "$out/json" && qualifyr check -y "$conditions" -f "$r1_summary" "$r2_summary" \
        -c "$confindr" -q "$quast" -b "$species" -z "$size_file" -s "$sample" -j -o .)
done < <(list_r1_files)

(cd "$out/json" && qualifyr report -i . \
    -c 'quast.N50,quast.# contigs (>= 0 bp),quast.# contigs (>= 1000 bp),quast.Total length (>= 1000 bp),quast.GC (%),confindr.contam_status,bactinspector.species' \
    -s 'Bash reproduction of GHRU Assembly Pipeline')
mv "$out/json"/qualifyr_report.* "$out/" 2>/dev/null || true
