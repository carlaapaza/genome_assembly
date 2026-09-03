#!/usr/bin/env bash
set -euo pipefail
source "$(cd "$(dirname "$0")/.." && pwd)/lib/common.sh"
require_cmd quast.py
assemblies="${OUTPUT_DIR}/09_assemblies"; out="${OUTPUT_DIR}/11_quast"
mkdir -p "$out/per_sample" "$out/combined"
fasta=()
while IFS= read -r -d '' file; do fasta+=("$file"); done \
    < <(find "$assemblies" -maxdepth 1 -type f -name '*.fasta' -print0 | sort -z)
(( ${#fasta[@]} > 0 )) || die "No filtered assemblies found"
for file in "${fasta[@]}"; do
    sample="$(basename "$file" .fasta)"
    quast.py "$file" --threads "$THREADS" --output-dir "${out}/per_sample/${sample}"
done
quast.py --no-plots --no-html --threads "$THREADS" "${fasta[@]}" --output-dir "$out/combined"
