# HW1 - Running Pipelines via Nextflow

**1.Install all requerments**
**nextflow**
```
$nextflow -version

      N E X T F L O W
      version 26.04.3 build 12259
      created 28-05-2026 08:48 UTC 
      cite doi:10.1038/nbt.3820
      http://nextflow.io
```
**docker**
```
$docker --version

Docker version 29.3.1, build c2be9cc
```
**conda**
```
$conda --version
conda 26.1.1
```
**2.Install pipeline rnaseq-nf**
```
$git clone https://github.com/nextflow-io/rnaseq-nf.git

Cloning into 'rnaseq-nf'...
remote: Enumerating objects: 1084, done.
remote: Counting objects: 100% (374/374), done.
remote: Compressing objects: 100% (96/96), done.
remote: Total 1084 (delta 334), reused 282 (delta 276), pack-reused 710 (from 2)
Receiving objects: 100% (1084/1084), 682.88 KiB | 3.50 MiB/s, done.
Resolving deltas: 100% (537/537), done.
```
**3.Run the rnaseq pipeline with docker**
```
$sudo nextflow run . -profile docker

 N E X T F L O W   ~  version 26.04.3
bash
Launching `./main.nf` [hopeful_poisson] revision: 313571027f

  R N A S E Q - N F   P I P E L I N E
  ===================================
  transcriptome: /media/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/data/ggal/ggal_1_48850000_49020000.Ggal71.500bpflank.fa
  reads        : /media/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/data/ggal/ggal_gut_{1,2}.fq
  outdir       : /media/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/results

executor >  local (4)
[ae/cc737a] RNA…Q:INDEX (ggal_1_48850000_49020000) | 1 of 1 ✔
[12/53d95a] RNASEQ:FASTQC (ggal_gut)               | 1 of 1 ✔
[e2/438d6e] RNASEQ:QUANT (ggal_gut)                | 1 of 1 ✔
[28/d44d9e] MULTIQC                                | 1 of 1 ✔

Outputs:

  media/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/results

  samples: samples.csv

  multiqc_report: multiqc_report.html

Completed at: 16-Jun-2026 10:49:09

Duration    : 1m 54s
CPU hours   : 0.1
Succeeded   : 4
```
**3.Run the rnaseq pipeline with conda**
```
$nextflow run . -profile conda -resume

 N E X T F L O W   ~  version 26.04.3

Launching `./main.nf` [deadly_gauss] revision: 313571027f

  R N A S E Q - N F   P I P E L I N E
  ===================================
  transcriptome: /media/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/data/ggal/ggal_1_48850000_49020000.Ggal71.500bpflank.fa
  reads        : /media/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/data/ggal/ggal_gut_{1,2}.fq
  outdir       : /media/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/results

executor >  local (1)
[4e/4219c5] RNA…Q:INDEX (ggal_1_48850000_49020000) | 1 of 1, cached: 1 ✔
[0f/f18a00] RNASEQ:FASTQC (ggal_gut)               | 1 of 1, cached: 1 ✔
[91/b39fc3] RNASEQ:QUANT (ggal_gut)                | 1 of 1, cached: 1 ✔
[ae/006cab] MULTIQC                                | 1 of 1 ✔

Outputs:

  /media/genomed/DATA_15Tb/emarenina/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/results

  samples: samples.csv

  multiqc_report: multiqc_report.html
```

**4.Download RNA-seq data**

Sample:
SAMN60669653 • SRS29541909 • All experiments • All runs
Organism: Gallus gallus
Library:
Name: Lh1
Instrument: Illumina NovaSeq 6000
Strategy: RNA-Seq
Source: TRANSCRIPTOMIC
Selection: RANDOM
Layout: PAIRED

```
$prefetch SRR39139867

2026-06-16T12:23:31 prefetch.3.0.3: Current preference is set to retrieve SRA Normalized Format files with full base quality scores.
2026-06-16T12:23:31 prefetch.3.0.3: 1) Downloading 'SRR39139867'...
2026-06-16T12:23:31 prefetch.3.0.3: SRA Normalized Format file is being retrieved, if this is different from your preference, it may be due to current file availability.
2026-06-16T12:23:31 prefetch.3.0.3:  Downloading via HTTPS...
2026-06-16T12:23:37 prefetch.3.0.3:  HTTPS download succeed
2026-06-16T12:23:37 prefetch.3.0.3:  'SRR39139867' is valid
2026-06-16T12:23:37 prefetch.3.0.3: 1) 'SRR39139867' was downloaded successfully
2026-06-16T12:23:37 prefetch.3.0.3: 'SRR39139867' has 0 unresolved dependencies

$fasterq-dump SRR39139867.sra 

spots read      : 20,986,521
reads read      : 41,973,042
reads written   : 41,973,042

$gzip *.fastq

```

**5.Run rnaseq-nf on my data**
```
$sudo nextflow run . \
  -profile docker \
  --reads '/media/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/SRR39139867/SRR39139867_{1,2}.fastq.gz' \
  -resume

 N E X T F L O W   ~  version 26.04.3

Launching `./main.nf` [trusting_kirch] revision: 313571027f

  R N A S E Q - N F   P I P E L I N E
  ===================================
  transcriptome: /media/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/data/ggal/ggal_1_48850000_49020000.Ggal71.500bpflank.fa
  reads        : /media/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/SRR39139867/SRR39139867_{1,2}.fastq.gz
  outdir       : /media/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/results

executor >  local (3)
[43/e724b9] RNA…Q:INDEX (ggal_1_48850000_49020000) | 1 of 1, cached: 1 ✔
[ba/e962d3] RNASEQ:FASTQC (SRR39139867)            | 1 of 1 ✔
[09/28a2a6] RNASEQ:QUANT (SRR39139867)             | 1 of 1 ✔
[7f/34e543] MULTIQC                                | 1 of 1 ✔

Outputs:

  /media/genomed/DATA_15Tb/emarenina/ITMO_BioinformaticsPipelines_2026/rnaseq-nf/results

  samples: samples.csv

  multiqc_report: multiqc_report.html

Completed at: 16-Jun-2026 12:53:13
Duration    : 5m 43s
CPU hours   : 0.2 (0.2% cached)
Succeeded   : 3
Cached      : 1
```
**DONE - ✔**


