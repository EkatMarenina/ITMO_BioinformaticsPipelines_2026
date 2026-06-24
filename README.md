# HW4: Multi-sample Nextflow Pipeline with Sample Grouping and Variant Filtering

## Description
This pipeline extends HW3 to support multi-sample input from a CSV samplesheet.
The key addition is sample grouping: samples are split into groups using `.branch{}`,
processed individually with group-specific parameters, then mixed back together
for the final variant filtering step.

## Features
- Multi-sample input from `samplesheet.csv`
- Sample metadata support via `sample` and `group` fields
- Single-end read processing
- Raw and trimmed read QC with FastQC
- **Sample grouping via `.branch{}`** — splits samples by group before trimming
- **Group-specific trimming parameters** — `sars-cov` group uses stricter quality
  threshold (Q30), `PCR-human` group uses standard threshold (Q20)
- **Channels merged back via `.mix()`** after individual processing
- Mapping with `bwa` + `samtools`
- Coverage plotting with safe handling of empty depth files
- Variant calling with `bcftools`
- Variant filtering with `bcftools view` (QUAL >= 20)
- `stub` mode support for fast workflow prototyping

## Repository Structure
```bash
ITMO_BioinformaticsPipelines_2026/
├── main.nf                          # Main Nextflow pipeline
├── nextflow.config                  # Configuration with 3 profiles
├── environment.yml                  # Conda dependencies
├── Dockerfile                       # Docker image for container profile
├── samplesheet.csv                  # Example input samplesheet
├── modules/
│   └── local/
│       └── trim_reads.nf           # Reusable TRIM_READS module (used with aliases)
└── README.md                        # This file
```

## Grouping Logic
Samples are split by the `group` field from the samplesheet using `.branch{}`:

```
sars-cov  → TRIM_READS_SARS  (Q30) ──┐
                                       ├─ .mix() → MAP_READS → ... → FILTER_VARIANTS
PCR-human → TRIM_READS_HUMAN (Q20) ──┘
```

## Input Format
The pipeline expects a CSV samplesheet with the following columns:
```csv
sample,group,path
s1,sars-cov,/path/to/SRR39133135.fastq.gz
s2,PCR-human,/path/to/SRR1175163.fastq.gz
```

| Column   | Description                            |
|----------|----------------------------------------|
| `sample` | Sample identifier                      |
| `group`  | Group name (`sars-cov` or `PCR-human`) |
| `path`   | Path to single-end FASTQ file          |

## Requirements
- Nextflow (>= 24.10.0)
- Java (>= 11)
- Conda or Docker

## Run

Local profile (Conda):
```bash
nextflow run main.nf \
  -profile local \
  --samplesheet samplesheet.csv \
  --reference data/ref/ecoli.fa \
  --outdir results
```

Cluster profile (SLURM):
```bash
nextflow run main.nf \
  -profile cluster \
  --samplesheet samplesheet.csv \
  --reference data/ref/ecoli.fa \
  --outdir results
```

Container profile (Docker):
```bash
nextflow run main.nf \
  -profile container \
  --samplesheet samplesheet.csv \
  --reference data/ref/ecoli.fa \
  --outdir results
```

## Stub Run
For fast development and testing without running actual tools:
```bash
nextflow run main.nf \
  --samplesheet samplesheet.csv \
  --reference data/ref/ecoli.fa \
  --outdir results_stub \
  -stub-run
```

## Output Structure
```bash
results/
├── fastqc_raw/          # FastQC reports for raw reads
├── trimmed/             # Trimmed reads (group-specific quality threshold)
├── fastqc_trimmed/      # FastQC reports for trimmed reads
├── mapping/             # BAM files and indices
├── coverage/            # Coverage depth files and plots
├── variants/            # Raw VCF files from bcftools
└── filtered_variants/   # Filtered VCF files (QUAL >= 20)
```

## Notes
- Grouping and individual processing is the core addition compared to HW3
- Quality threshold per group can be adjusted directly in `main.nf` in the `.map{}` calls
- Coverage plotting handles empty or missing depth files without crashing
- The `TRIM_READS` process is defined once in `modules/local/trim_reads.nf`
  and imported with two aliases to avoid code duplication
```
