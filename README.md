# HW3: Nextflow Pipeline for NGS Processing with Variant Calling

## Description

This pipeline processes paired-end NGS data from SRA, performs quality control, trimming, alignment to a reference genome, coverage plotting, and **variant calling** using `bcftools`.

## Features

- SRA data download by accession number
- Quality control of raw and trimmed reads (`FastQC`)
- Adapter trimming and filtering (`fastp`)
- Read alignment to reference genome (`bwa mem` + `samtools`)
- Coverage plot generation (R + `ggplot2`)
- **Variant calling** (`bcftools mpileup + call`)
- Three execution profiles: `local`, `cluster`, `container`

## Repository Structure
```bash
ITMO_BioinformaticsPipelines_2026/
├── main.nf # Main Nextflow pipeline
├── nextflow.config # Configuration with 3 profiles
├── environment.yml # Conda dependencies
├── Dockerfile # Docker image for container profile
└── README.md # This file
```
## System Requirements

- **Nextflow** (>= 22.10.0)
- **Conda** or **Mamba** (for local/cluster profiles)
- **Docker** (optional, for container profile)
- **Java** (>= 11)

## Quick Start
**1. Clone the repository**
```bash
git clone https://github.com/EkatMarenina/ITMO_BioinformaticsPipelines_2026.git
cd ITMO_BioinformaticsPipelines_2026
git checkout HW3
```

**2. Create Conda environment**
```bash
# Create environment from environment.yml
conda env create -f environment.yml -n hw3-pipeline

# Activate environment
conda activate hw3-pipeline
```

**3. Download reference genome (E. coli)**
```bash
mkdir -p data/ref
cd data/ref
wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz
gunzip GCF_000005845.2_ASM584v2_genomic.fna.gz
mv GCF_000005845.2_ASM584v2_genomic.fna ecoli.fa
cd ../..
```

**4. Run the pipeline**
**local profile (local execution with Conda)**
```bash
nextflow run main.nf -profile local \
  --conda_env hw3-pipeline \
  --reference data/ref/ecoli.fa \
  --accession ERR16112907 \
  --outdir results
```
**cluster profile (SLURM cluster execution)**
```bash
nextflow run main.nf -profile cluster \
  --reference data/ref/ecoli.fa \
  --accession ERR16112907 \
  --outdir results
```
**container profile (Docker execution)**
```bash
# Build Docker image (once)
docker build -t ekatmarenina/hw3-pipeline:latest .

# Run pipeline
nextflow run main.nf -profile container \
  --reference data/ref/ecoli.fa \
  --accession ERR16112907 \
  --outdir results
```

## Output Structure
```bash
After successful execution, the results/ directory will contain:
results/
├── fastqc_raw/          # FastQC reports for raw reads
├── trimmed/             # Trimmed reads (fastp output)
├── fastqc_trimmed/      # FastQC reports for trimmed reads
├── mapping/             # BAM files and indices
├── coverage/            # Coverage depth files and plots
└── variants/            # VCF files with variants
    ├── ERR16112907.vcf.gz   # Compressed VCF
    └── ERR16112907.vcf.gz.tbi # VCF index
```
