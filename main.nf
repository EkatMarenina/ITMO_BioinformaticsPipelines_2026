#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

params.accession = "ERR16112907"
params.reference = "data/ref/ecoli.fa"
params.outdir    = "results"
params.conda_env = null
params.container = "yourdockerhubuser/hw3-pipeline:latest"

include { FASTQC as FASTQC_RAW     } from './modules/local/fastqc'
include { FASTQC as FASTQC_TRIMMED } from './modules/local/fastqc'
include { BCFTOOLS_FILTER          } from './modules/nf-core/bcftools/filter/main'

process TRIM_READS {
    tag "${meta.id}"
    publishDir "${params.outdir}/trimmed", mode: 'copy'

    input:
    tuple val(meta), path(r1), path(r2)

    output:
    tuple val(meta), path("${meta.id}_1.fq.gz"), path("${meta.id}_2.fq.gz")

    script:
    """
    fastp -i ${r1} -I ${r2} -o ${meta.id}_1.fq.gz -O ${meta.id}_2.fq.gz
    """
}

process MAP_READS {
    tag "${meta.id}"
    publishDir "${params.outdir}/mapping", mode: 'copy'

    input:
    tuple val(meta), path(r1), path(r2), path(ref)

    output:
    tuple val(meta), path("${meta.id}.bam"), path("${meta.id}.bam.bai")

    script:
    """
    bwa index ${ref}
    bwa mem -t ${task.cpus} ${ref} ${r1} ${r2} | samtools sort -@ ${task.cpus} -o ${meta.id}.bam
    samtools index ${meta.id}.bam
    """
}

process PLOT_COVERAGE {
    tag "${meta.id}"
    publishDir "${params.outdir}/coverage", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    path "${meta.id}_depth.txt"
    path "${meta.id}_coverage.png"

    script:
    """
    samtools depth ${bam} > ${meta.id}_depth.txt
    cat <<'EOF' > plot_coverage.R
#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
sample_id <- args[1]
depth_file <- paste0(sample_id, "_depth.txt")
output_png <- paste0(sample_id, "_coverage.png")
data <- read.table(depth_file, header=FALSE, col.names=c("contig", "pos", "cov"))
png(output_png, width=14, height=6, units="in", res=150)
plot(data[["pos"]], data[["cov"]], type="l", col="blue", lwd=0.5,
     xlab="Genome Position (bp)", ylab="Coverage Depth",
     main=paste("Coverage Plot for", sample_id), cex.lab=1.2)
avg_cov <- mean(data[["cov"]])
abline(h=avg_cov, col="red", lty=2, lwd=1.5)
legend("topright", legend=c(paste("Mean coverage:", round(avg_cov, 1), "x")),
       col="red", lty=2, lwd=1.5)
grid(col="gray", lty=3)
dev.off()
EOF
    chmod +x plot_coverage.R
    Rscript plot_coverage.R ${meta.id}
    """
}

process VARIANT_CALLING {
    tag "${meta.id}"
    publishDir "${params.outdir}/variants", mode: 'copy'

    input:
    tuple val(meta), path(bam), path(bai), path(ref)

    output:
    tuple val(meta), path("${meta.id}.vcf.gz"), path("${meta.id}.vcf.gz.tbi")

    script:
    """
    bcftools mpileup -f ${ref} ${bam} -Ou | bcftools call -mv -Oz -o ${meta.id}.vcf.gz
    tabix -p vcf ${meta.id}.vcf.gz
    """
}

workflow {
    sra_ch = Channel.fromSRA(params.accession)

    // Добавляем stage: "raw" в meta сразу при создании канала
    reads_ch = sra_ch.map { entry ->
        [ [id: entry[0], stage: "raw"], entry[1][0], entry[1][1] ]
    }

    // FastQC на сырых ридах
    FASTQC_RAW(reads_ch)

    // Тримминг
    trimmed_ch = TRIM_READS(reads_ch)

    // FastQC на триммированных — меняем stage в meta
    trimmed_fastqc_ch = trimmed_ch.map { meta, r1, r2 ->
        [ [id: meta.id, stage: "trimmed"], r1, r2 ]
    }
    FASTQC_TRIMMED(trimmed_fastqc_ch)

    ref_file = file(params.reference, checkIfExists: true)

    // Маппинг
    mapped_ch = MAP_READS(
        trimmed_ch.map { meta, r1, r2 -> tuple(meta, r1, r2, ref_file) }
    )

    // Покрытие
    PLOT_COVERAGE(mapped_ch)

    // Вариантный колл
    variants_ch = VARIANT_CALLING(
        mapped_ch.map { meta, bam, bai -> tuple(meta, bam, bai, ref_file) }
    )

    // Фильтрация вариантов через nf-core модуль
    BCFTOOLS_FILTER(variants_ch)

    log.info "Pipeline complete"
}
