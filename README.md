# Short-read bacterial assembly

A transparent Bash reimplementation of the major stages in the CGPS/GHRU
SPAdes assembly workflow, adapted for paired-end Illumina bacterial data and a
macOS Apple Silicon host.

The repository preserves the original workflow logic while keeping each stage
independently runnable and inspectable.

## Workflow

1. FastQC + MultiQC
2. Cutadapt + Trimmomatic (Optional)
3. FastQC + MultiQC
4. KAT + Mash + Lighter 
5. ConFindr
6. seqtk
7. FLASH
8. SPAdes
9. Python filter for sequences >=500 bp and >=3x
10. BactInspector for species screening
11. QUAST + MultiQC

## Quick start on macOS Apple Silicon

Docker Desktop is recommended because Lighter, FLASH, ConFindr, BactInspector
and QualiFyr have old dependencies that are frequently unavailable for osx-arm64.
The wrapper requests Linux/amd64 emulation.

```bash
cd /Users/carlaapaza/Desktop/genome_assembly
docker pull registry.gitlab.com/cgps/ghru/pipelines/dsl2/pipelines/assembly:latest
```

Place paired reads in `data/raw/` using names such as:

```text
UPCH_0668_1.fastq.gz
UPCH_0668_2.fastq.gz
```

Edit `config/config.env`, especially `THREADS` and `SPADES_MEMORY_GB`, then run:

```bash
./bin/run-in-docker ./run_all.sh
```

Run one stage again with, for example:

```bash
./bin/run-in-docker ./scripts/11_quast.sh
```

Results are written to `results/` in numbered directories. Scripts skip many
existing final products, but `results/` should be moved or removed before a
fully clean rerun.

## Native Conda option

```bash
conda env create -f environment.yml
conda activate genome-assembly
./run_all.sh
```

This option is principally for Linux. It may not solve completely on an Apple
Silicon Mac because several legacy packages were never built for osx-arm64.
The container is therefore the documented reproducible execution method.

## Configuration notes

- `DEPTH_CUTOFF=150` approximates the original optional depth cap.
- Downsampling uses the fixed seed `12345`.
- `SPADES_CAREFUL=false` matches the upstream default.
- The final file is a filtered scaffold FASTA, matching the upstream workflow.
  For annotation projects that prefer contigs, change the input in
  `scripts/09_filter_assemblies.sh` from `scaffolds.fasta` to `contigs.fasta`.
- The included QC ranges are an explicit *H. pylori* profile and should be
  treated as screening thresholds, not proof of biological purity.
- QualiFyr is retained as an optional legacy step because its accepted input
  schemas vary across releases. Run `scripts/13_qualifyr.sh` after the default
  workflow; inspect its classifications rather than treating them as diagnoses.

## Reproducibility

Record the container identity used for an analysis:

```bash
docker image inspect \
  registry.gitlab.com/cgps/ghru/pipelines/dsl2/pipelines/assembly:latest \
  --format '{{index .RepoDigests 0}}' > container-digest.txt
```

Commit `container-digest.txt` and replace `:latest` in `bin/run-in-docker` with
the resulting `@sha256:...` digest. Also commit the configuration file and the
software/version output produced by:

```bash
./bin/run-in-docker bash -lc 'for p in fastqc multiqc trimmomatic cutadapt mash kat lighter seqtk flash spades.py confindr.py bactinspector quast.py qualifyr; do command -v "$p" || true; done'
```

## Attribution

Workflow design adapted from the
[CGPS/GHRU SPAdes Assembly workflow](https://gitlab.com/cgps/ghru/pipelines/dsl2/pipelines/assembly),
version 2.1.3 (source commit `ad87f10e79fe6c6c2f0033d15b849393a3bc9061`),
which was itself based on Shovill. This repository is an
independent Bash organization of the workflow.
