#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd trimmomatic; assert_inputs
[[ "$RUN_CUTADAPT" == "false" ]] || require_cmd cutadapt

out="${OUTPUT_DIR}/02_trimmed_reads"
mkdir -p "$out" "${OUTPUT_DIR}/logs/trimming"

while IFS= read -r -d '' r1; do
    sample="$(sample_from_r1 "$r1")"; r2="${INPUT_DIR}/${sample}${R2_SUFFIX}"
    t1="${out}/${sample}_1.trimmed.fastq.gz"; t2="${out}/${sample}_2.trimmed.fastq.gz"
    [[ -s "$t1" && -s "$t2" ]] && { msg "Trimming already complete: $sample"; continue; }

    mean_length="$(gzip -cd "$r1" | awk 'NR%4==2{s+=length($0);n++} n==100000{exit} END{if(n)printf "%.0f",s/n}')"
    min_length="$(( mean_length * 30 / 100 ))"
    (( min_length < 1 )) && min_length=1
    msg "Trimming $sample (mean read=${mean_length} bp; MINLEN=${min_length})"

    in1="$r1"; in2="$r2"
    if [[ "$RUN_CUTADAPT" == "true" ]]; then
        pre1="${out}/${sample}_1.cutadapt.fastq.gz"; pre2="${out}/${sample}_2.cutadapt.fastq.gz"
        cutadapt -j "$THREADS" -m 50 -a "file:${ADAPTER_FILE}" -A "file:${ADAPTER_FILE}" \
            -o "$pre1" -p "$pre2" "$r1" "$r2"
        in1="$pre1"; in2="$pre2"
    fi

    run_logged "${OUTPUT_DIR}/logs/trimming/${sample}.log" \
        trimmomatic PE -threads "$THREADS" -phred33 \
        "$in1" "$in2" "$t1" /dev/null "$t2" /dev/null \
        "ILLUMINACLIP:${ADAPTER_FILE}:2:30:10" SLIDINGWINDOW:4:20 LEADING:25 TRAILING:25 "MINLEN:${min_length}"
done < <(list_r1_files)

