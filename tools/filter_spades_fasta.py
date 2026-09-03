#!/usr/bin/env python3
"""Filter a SPAdes FASTA using length and coverage encoded in its headers."""
import argparse
import re

COV = re.compile(r"(?:^|_)cov_([0-9]+(?:\.[0-9]+)?)")

def records(path):
    header = None
    seq = []
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.rstrip("\n")
            if line.startswith(">"):
                if header is not None:
                    yield header, "".join(seq)
                header, seq = line, []
            else:
                seq.append(line.strip())
        if header is not None:
            yield header, "".join(seq)

parser = argparse.ArgumentParser()
parser.add_argument("-i", "--input", required=True)
parser.add_argument("-o", "--output", required=True)
parser.add_argument("--min-length", type=int, default=500)
parser.add_argument("--min-coverage", type=float, default=3.0)
args = parser.parse_args()

seen = kept = 0
with open(args.output, "w", encoding="utf-8") as out:
    for header, seq in records(args.input):
        seen += 1
        match = COV.search(header)
        if len(seq) >= args.min_length and match and float(match.group(1)) >= args.min_coverage:
            kept += 1
            out.write(f"{header}\n")
            for pos in range(0, len(seq), 80):
                out.write(seq[pos:pos+80] + "\n")
print(f"Starting sequences: {seen}; kept: {kept}")
if kept == 0:
    raise SystemExit("No sequences passed the filters")

