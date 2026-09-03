#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd seqtk
corrected="${OUTPUT_DIR}/04_corrected_reads"; out="${OUTPUT_DIR}/06_downsampled_reads"
stats="${OUTPUT_DIR}/metrics/genome_size.tsv"; depth_table="${OUTPUT_DIR}/metrics/read_depth.tsv"
[[ -s "$stats" ]] || die "Genome-size table not found: $stats"
mkdir -p "$out"; printf 'sample\tbases\tgenome_size_bp\testimated_depth\tfraction_kept\n' > "$depth_table"

while IFS= read -r -d '' original_r1; do
    sample="$(sample_from_r1 "$original_r1")"
    r1="${corrected}/${sample}_1.corrected.fastq.gz"; r2="${corrected}/${sample}_2.corrected.fastq.gz"
    genome_size="$(awk -F'\t' -v s="$sample" '$1==s{print $2}' "$stats")"
    bases1="$(seqtk fqchk "$r1" | awk '$1=="ALL"{print $2}')"
    bases2="$(seqtk fqchk "$r2" | awk '$1=="ALL"{print $2}')"
    bases="$((bases1 + bases2))"; depth="$(awk -v b="$bases" -v g="$genome_size" 'BEGIN{printf "%.2f",b/g}')"
    fraction="$(awk -v d="$depth" -v c="$DEPTH_CUTOFF" 'BEGIN{f=(d>c?c/d:1); printf "%.8f",f}')"
    printf '%s\t%s\t%s\t%s\t%s\n' "$sample" "$bases" "$genome_size" "$depth" "$fraction" >> "$depth_table"
    for mate in 1 2; do
        input="${corrected}/${sample}_${mate}.corrected.fastq.gz"
        output="${out}/${sample}_${mate}.downsampled.fastq.gz"
        if awk -v f="$fraction" 'BEGIN{exit !(f<0.999999)}'; then
            seqtk sample -s 12345 "$input" "$fraction" | gzip -c > "$output"
        else
            ln -sf "$input" "$output"
        fi
    done
done < <(list_r1_files)

