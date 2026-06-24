# HW3: Nextflow Pipeline for NGS Processing with Variant Calling

## Description
This pipeline processes paired-end NGS data from SRA, performs quality control,
trimming, alignment to a reference genome, coverage plotting, variant calling,
and variant filtering using `bcftools`.

## Features
- SRA data download by accession number
- Quality control of raw and trimmed reads (`FastQC`) — single reusable process
  imported with two aliases (`FASTQC_RAW` / `FASTQC_TRIMMED`) to avoid code duplication
- Adapter trimming and filtering (`fastp`)
- Read alignment to reference genome (`bwa mem` + `samtools`)
- Coverage plot generation (R)
- Variant calling (`bcftools mpileup + call`)
- Variant filtering via nf-core module (`bcftools/filter`, QUAL>=20 && DP>=10)
- Three execution profiles: `local`, `cluster`, `container`

## Repository Structure
```bash
ITMO_BioinformaticsPipelines_2026/
├── main.nf                          # Main Nextflow pipeline
├── nextflow.config                  # Configuration with 3 profiles
├── environment.yml                  # Conda dependencies
├── Dockerfile                       # Docker image for container profile
├── modules/
│   ├── local/
│   │   └── fastqc.nf               # Reusable FASTQC module (used with aliases)
│   └── nf-core/
│       └── bcftools/
│           └── filter/
│               └── main.nf         # nf-core BCFTOOLS_FILTER module
└── README.md                        # This file
```

## System Requirements
- **Nextflow** (>= 24.10.0)
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
conda env create -f environment.yml -n hw3-pipeline
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

Local profile (Conda):
```bash
nextflow run main.nf -profile local \
  --conda_env hw3-pipeline \
  --reference data/ref/ecoli.fa \
  --accession ERR16112907 \
  --outdir results
```

Cluster profile (SLURM):
```bash
nextflow run main.nf -profile cluster \
  --reference data/ref/ecoli.fa \
  --accession ERR16112907 \
  --outdir results
```

Container profile (Docker):
```bash
docker build -t ekatmarenina/hw3-pipeline:latest .
nextflow run main.nf -profile container \
  --reference data/ref/ecoli.fa \
  --accession ERR16112907 \
  --outdir results
```

## Output Structure
```bash
results/
├── fastqc/                          # FastQC reports (raw_ and trimmed_ prefixed)
├── trimmed/                         # Trimmed reads (fastp output)
├── mapping/                         # BAM files and indices
├── coverage/                        # Coverage depth files and plots
├── variants/                        # Raw VCF files
│   ├── ERR16112907.vcf.gz
│   └── ERR16112907.vcf.gz.tbi
└── filtered_variants/               # Filtered VCF files (QUAL>=20 && DP>=10)
    ├── ERR16112907_filtered.vcf.gz
    └── ERR16112907_filtered.vcf.gz.tbi
```
