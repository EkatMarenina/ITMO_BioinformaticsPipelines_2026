# HW4: Multi-sample Nextflow pipeline with variant filtering

This homework continues the HW3 pipeline and adds support for multi-sample input from a CSV samplesheet, variant filtering, and stub-based development.  
The pipeline was updated to work with **single-end (SE)** input, and the coverage plotting step was improved to handle empty coverage files safely.

## Features

- Multi-sample input from `samplesheet.csv`.
- Sample metadata support via `sample` and `group` fields.
- Single-end read processing.
- Raw and trimmed read QC with FastQC.
- Read trimming with fastp.
- Mapping with bwa + samtools.
- Coverage plotting with a safer `PLOT_COVERAGE` process.
- Variant calling with bcftools.
- Variant filtering with bcftools view.
- `stub` mode support for fast workflow prototyping.

## Input format

The pipeline expects a CSV samplesheet with the following columns:

```csv
sample,group,path
s1,sars-cov,/path/to/SRR39133135.fastq.gz
s2,PCR-human,/path/to/SRR1175163.fastq.gz
```

### Column description
```bash
- `sample` — sample identifier.
- `group` — group name used for sample metadata.
- `path` — path to the single-end FASTQ file.
```
## Requirements
```bash
- Nextflow
- Conda
- fastqc
- fastp
- bwa
- samtools
- bcftools
- tabix
- htslib
- R
- r-ggplot2
```
## What was updated in HW4

Compared to HW3, I updated:

- the configuration file;
- the conda environment file;
- the pipeline to support **single-end** input;
- the coverage plotting step to avoid crashing on empty depth files.

## Run

### Local

```bash
nextflow run main.nf \
  -profile local \
  --samplesheet samplesheet.csv \
  --reference data/ref/ecoli.fa \
  --outdir results
```

If you use a local conda environment path:

```bash
nextflow run main.nf \
  -profile local \
  --samplesheet samplesheet.csv \
  --reference data/ref/ecoli.fa \
  --outdir results \
  --conda_env /path/to/your/hw4-env
```

### Cluster

```bash
nextflow run main.nf \
  -profile cluster \
  --samplesheet samplesheet.csv \
  --reference data/ref/ecoli.fa \
  --outdir results
```

### Container

```bash
nextflow run main.nf \
  -profile container \
  --samplesheet samplesheet.csv \
  --reference data/ref/ecoli.fa \
  --outdir results
```

## Stub run

For fast development and testing, the pipeline supports stub mode:

```bash
nextflow run main.nf \
  -profile local \
  --samplesheet samplesheet.csv \
  --reference data/ref/ecoli.fa \
  --outdir results_stub \
  -stub-run
```

## Output

The pipeline creates the following output directories:

- `fastqc_raw/`
- `trimmed/`
- `fastqc_trimmed/`
- `mapping/`
- `coverage/`
- `variants/`
- `filtered_variants/`

## Notes

- The pipeline is designed for single-end FASTQ input.
- Coverage plotting was improved so that samples with empty or missing coverage do not break the workflow.
- The final variant filtering step uses a simple QUAL threshold.

## Example filtering logic

The filtering step keeps variants with:

- `QUAL >= 20`

This threshold can be adjusted in `nextflow.config` or by parameter if needed.

## Files

- `main.nf` — main workflow script.
- `nextflow.config` — configuration with local, cluster and container profiles.
- `environment.yml` — conda environment for the pipeline.
- `Dockerfile` — container image definition.
- `samplesheet.csv` — example input table.
