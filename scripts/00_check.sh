#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"

for program in fastqc multiqc trimmomatic cutadapt kat jq mash lighter seqtk flash spades.py confindr.py bactinspector quast.py qualifyr python; do
    require_cmd "$program"
done
assert_inputs
mkdir -p "$OUTPUT_DIR"
msg "Inputs and programs validated."

