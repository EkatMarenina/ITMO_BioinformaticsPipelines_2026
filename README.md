# Bioinformatics Pipelines - HW2

Nextflow pipeline for processing paired-end NGS data with QC, trimming, mapping, and coverage visualization by me.

This pipeline performs a complete bioinformatics analysis workflow:
- Quality control of raw reads
- Adapter trimming and read filtering
- Quality control of trimmed reads
- Reference genome indexing
- Read mapping to reference genome
- Coverage analysis and visualization

### Preparation to start pipeline

0. **Dependencies**

All dependencies are managed via conda (environment.yml)

1. **Create conda environment**

bash
conda env create -f environment.yml
conda activate nextflow-pipeline

2. **Prepare reference genome**

bash
mkdir -p data/ref
# Download E.coli reference genome
wget -O data/ref/ecoli.fa.gz \
  "https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz"
gunzip data/ref/ecoli.fa.gz

### Run Pipeline

nextflow run main.nf

### Pipeline Steps

Step	Process	Tool	Description
1.	FASTQC_RAW	FastQC	Quality control of raw reads
2.	TRIM_READS	fastp	Adapter trimming and quality filtering
3.	FASTQC_TRIMMED	FastQC	Quality control after trimming
4.	INDEX_REF	BWA	Index reference genome
5.	MAP_READS	BWA + SAMtools	Map reads to reference and sort BAM
6.	PLOT_COVERAGE	SAMtools + R	Generate coverage plot and statistics

### Output directory structure

```text
results/
├── fastqc_raw/ # FastQC reports for raw reads
│   ├── ERR16112907_1_fastqc.html
│   └── ERR16112907_2_fastqc.html
├── fastqc_trimmed/ # FastQC reports for trimmed reads
│   ├── ERR16112907_1_fastqc.html
│   └── ERR16112907_2_fastqc.htm
├── trimmed/ # Trimmed FASTQ files
│   ├── ERR16112907_1.fq.gz
│   └── ERR16112907_2.fq.gz
├── mapping/ # Alignment files
│   ├── ERR16112907.bam
│   └── ERR16112907.bam.bai
└── coverage/ # Coverage analysis
    ├── ERR16112907_depth.txt
    └── ERR16112907_coverage.png
```
