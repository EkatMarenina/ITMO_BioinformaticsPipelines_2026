#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

params.samplesheet = params.samplesheet ?: null
params.reference   = params.reference ?: "data/ref/ecoli.fa"
params.outdir      = params.outdir ?: "results"
params.conda_env   = params.conda_env ?: null
params.container   = params.container ?: "yourdockerhubuser/hw3-pipeline:latest"
params.qual_cutoff = params.qual_cutoff ?: 20

process FASTQC_RAW {
    tag "${meta.id}"
    publishDir "${params.outdir}/fastqc_raw", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    path "*.html"

    script:
    """
    fastqc ${reads} --noextract
    """
    stub:
    """
    touch ${meta.id}_fastqc.html
    """
}

process TRIM_READS {
    tag "${meta.id}"
    publishDir "${params.outdir}/trimmed", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.trimmed.fastq.gz")

    script:
    """
    fastp -i ${reads} -o ${meta.id}.trimmed.fastq.gz
    """
    stub:
    """
    touch ${meta.id}.trimmed.fastq.gz
    """
}

process FASTQC_TRIMMED {
    tag "${meta.id}"
    publishDir "${params.outdir}/fastqc_trimmed", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    path "*.html"

    script:
    """
    fastqc ${reads} --noextract
    """
    stub:
    """
    touch ${meta.id}.trimmed_fastqc.html
    """
}

process MAP_READS {
    tag "${meta.id}"
    publishDir "${params.outdir}/mapping", mode: 'copy'

    input:
    tuple val(meta), path(reads), path(ref)

    output:
    tuple val(meta), path("${meta.id}.bam"), path("${meta.id}.bam.bai")

    script:
    """
    bwa index ${ref}
    bwa mem -t ${task.cpus} ${ref} ${reads} | samtools sort -@ ${task.cpus} -o ${meta.id}.bam
    samtools index ${meta.id}.bam
    """
    stub:
    """
    touch ${meta.id}.bam
    touch ${meta.id}.bam.bai
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

if (!file.exists(depth_file) || file.info(depth_file)\$size == 0) {
  png(output_png, width=14, height=6, units="in", res=150)
  plot.new()
  text(0.5, 0.5, paste("No coverage data for", sample_id))
  dev.off()
  quit(status = 0)
}

data <- read.table(depth_file, header = FALSE, col.names = c("contig", "pos", "cov"))

if (nrow(data) == 0) {
  png(output_png, width=14, height=6, units="in", res=150)
  plot.new()
  text(0.5, 0.5, paste("No coverage data for", sample_id))
  dev.off()
  quit(status = 0)
}

png(output_png, width=14, height=6, units="in", res=150)
plot(data\$pos, data\$cov,
     type = "l",
     col = "blue",
     lwd = 0.5,
     xlab = "Genome Position (bp)",
     ylab = "Coverage Depth",
     main = paste("Coverage Plot for", sample_id),
     cex.lab = 1.2)

avg_cov <- mean(data\$cov)
abline(h = avg_cov, col = "red", lty = 2, lwd = 1.5)

legend("topright",
       legend = c(paste("Mean coverage:", round(avg_cov, 1), "x")),
       col = "red",
       lty = 2,
       lwd = 1.5)

grid(col = "gray", lty = 3)
dev.off()
EOF

    chmod +x plot_coverage.R
    Rscript plot_coverage.R ${meta.id}
    """
    stub:
    """
    touch ${meta.id}_depth.txt
    touch ${meta.id}_coverage.png
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
    stub:
    """
    echo "" | bgzip -c > ${meta.id}.vcf.gz
    touch ${meta.id}.vcf.gz.tbi
    """
}

process FILTER_VARIANTS {
    tag "${meta.id}"
    publishDir "${params.outdir}/filtered_variants", mode: 'copy'

    input:
    tuple val(meta), path(vcf), path(tbi)

    output:
    tuple val(meta), path("${meta.id}.filtered.vcf.gz"), path("${meta.id}.filtered.vcf.gz.tbi")

    script:
    """
    bcftools view -i 'QUAL>=${params.qual_cutoff}' -Oz -o ${meta.id}.filtered.vcf.gz ${vcf}
    tabix -p vcf ${meta.id}.filtered.vcf.gz
    """
    stub:
    """
    echo "" | bgzip -c > ${meta.id}.filtered.vcf.gz
    touch ${meta.id}.filtered.vcf.gz.tbi
    """
}

workflow {
    if (!params.samplesheet) {
        error "Please provide --samplesheet"
    }
    if (!params.reference) {
        error "Please provide --reference"
    }

    raw_reads_ch = Channel
        .fromPath(params.samplesheet, checkIfExists: true)
        .splitCsv(header: true)
        .map { row ->
            tuple(
                [id: row.sample, group: row.group],
                file(row.path, checkIfExists: true)
            )
        }

    FASTQC_RAW(raw_reads_ch)
    trimmed_ch = TRIM_READS(raw_reads_ch)
    FASTQC_TRIMMED(trimmed_ch)

    ref_file = file(params.reference, checkIfExists: true)

    mapped_ch = MAP_READS(trimmed_ch.map { meta, reads -> tuple(meta, reads, ref_file) })
    PLOT_COVERAGE(mapped_ch)

    variants_ch = VARIANT_CALLING(mapped_ch.map { meta, bam, bai -> tuple(meta, bam, bai, ref_file) })
    FILTER_VARIANTS(variants_ch)
    
    log.info "Pipeline complete"
}
