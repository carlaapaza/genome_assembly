#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${CONFIG_FILE:-${PROJECT_DIR}/config/config.env}"

[[ -f "$CONFIG_FILE" ]] || { echo "Configuration not found: $CONFIG_FILE" >&2; exit 1; }
# shellcheck disable=SC1090
source "$CONFIG_FILE"

abspath() {
    case "$1" in
        /*) printf '%s\n' "$1" ;;
        *) printf '%s/%s\n' "$PROJECT_DIR" "$1" ;;
    esac
}

INPUT_DIR="$(abspath "$INPUT_DIR")"
OUTPUT_DIR="$(abspath "$OUTPUT_DIR")"
ADAPTER_FILE="$(abspath "$ADAPTER_FILE")"

msg() { printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }
die() { msg "ERROR: $*" >&2; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "Program not found: $1"; }

sample_from_r1() {
    local name
    name="$(basename "$1")"
    printf '%s\n' "${name%${R1_SUFFIX}}"
}

list_r1_files() {
    find "$INPUT_DIR" -maxdepth 1 -type f -name "*${R1_SUFFIX}" -print0 | sort -z
}

assert_inputs() {
    [[ -d "$INPUT_DIR" ]] || die "Input directory not found: $INPUT_DIR"
    [[ -s "$ADAPTER_FILE" ]] || die "Adapter FASTA not found: $ADAPTER_FILE"
    local found=0 r1 sample r2
    while IFS= read -r -d '' r1; do
        found=1
        sample="$(sample_from_r1 "$r1")"
        r2="${INPUT_DIR}/${sample}${R2_SUFFIX}"
        [[ -s "$r2" ]] || die "R2 missing for ${sample}: $r2"
    done < <(list_r1_files)
    (( found == 1 )) || die "No files matching *${R1_SUFFIX} in $INPUT_DIR"
}

run_logged() {
    local log_file="$1"
    shift
    mkdir -p "$(dirname "$log_file")"
    "$@" 2>&1 | tee "$log_file"
}

