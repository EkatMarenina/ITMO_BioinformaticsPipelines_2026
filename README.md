# ITMO_BioinformaticsPipelines_2026
Homeworks for course "Bioinformatics Pipelines" by ITMO University

# HW3

Nextflow pipeline for paired-end NGS processing with variant calling.

## Features
- SRA input
- QC of raw and trimmed reads
- Trimming with fastp
- Mapping with bwa + samtools
- Coverage plotting
- Variant calling with bcftools

## Profiles
- local: use a local conda environment
- cluster: use conda environment.yml
- container: use Docker image

## Run

### Local
```bash
nextflow run main.nf -profile local \
  --accession ERR16112907 \
  --reference data/ref/ecoli.fa \
  --conda_env /path/to/conda/env

### Cluster
```bash
nextflow run main.nf -profile cluster \
  --accession ERR16112907 \
  --reference data/ref/ecoli.fa

### Container
```bash
nextflow run main.nf -profile container \
  --accession ERR16112907 \
  --reference data/ref/ecoli.fa
