#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")" && pwd)"
for stage in \
    00_check.sh \
    01_fastqc_raw.sh \
    02_trim.sh \
    03_fastqc_trimmed.sh \
    04_estimate_and_correct.sh \
    05_confindr.sh \
    06_downsample.sh \
    07_merge.sh \
    08_spades.sh \
    09_filter_assemblies.sh \
    10_species_id.sh \
    11_quast.sh \
    12_multiqc.sh \
    13_qualifyr.sh
do
    printf '\n===== %s =====\n' "$stage"
    "${root}/scripts/${stage}"
done
