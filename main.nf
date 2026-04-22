#!/usr/bin/env nextflow

params.accession = "ERR16112907"
params.reference = "data/ref/ecoli.fa"
params.outdir = "results"

process FASTQC_RAW {
    publishDir "${params.outdir}/fastqc_raw", mode: 'copy'
    input:
    tuple val(id), path(r1), path(r2)
    output:
    path "*.html"
    script:
    "fastqc ${r1} ${r2} --noextract"
}

process TRIM_READS {
    publishDir "${params.outdir}/trimmed", mode: 'copy'
    input:
    tuple val(id), path(r1), path(r2)
    output:
    tuple val(id), path("${id}_1.fq.gz"), path("${id}_2.fq.gz")
    script:
    """
    fastp -i ${r1} -I ${r2} -o ${id}_1.fq.gz -O ${id}_2.fq.gz
    """
}

process FASTQC_TRIMMED {
    publishDir "${params.outdir}/fastqc_trimmed", mode: 'copy'
    input:
    tuple val(id), path(r1), path(r2)
    output:
    path "*.html"
    script:
    "fastqc ${r1} ${r2} --noextract"
}

process INDEX_REF {
    publishDir "${params.outdir}/ref_index", mode: 'copy'
    input:
    path ref
    output:
    path "${ref}.amb"
    path "${ref}.ann"
    path "${ref}.bwt"
    path "${ref}.pac"
    path "${ref}.sa"
    script:
    """
    bwa index ${ref}
    """
}

process MAP_READS {
    publishDir "${params.outdir}/mapping", mode: 'copy'
    input:
    tuple val(id), path(r1), path(r2)
    path ref
    output:
    tuple val(id), path("${id}.bam"), path("${id}.bam.bai")
    script:
    """
    bwa index ${ref}
    bwa mem ${ref} ${r1} ${r2} | samtools sort -o ${id}.bam
    samtools index ${id}.bam
    """
}

process PLOT_COVERAGE {
    publishDir "${params.outdir}/coverage", mode: 'copy'
    input:
    tuple val(id), path(bam), path(bai)
    output:
    path "${id}_depth.txt"
    path "${id}_coverage.png"
    script:
    """
    samtools depth ${bam} > ${id}_depth.txt
    
    cat <<'EOF' > plot_coverage.R
#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
sample_id <- args[1]
depth_file <- paste0(sample_id, "_depth.txt")
output_png <- paste0(sample_id, "_coverage.png")

data <- read.table(depth_file, header=FALSE, 
                  col.names=c("contig", "pos", "cov"))

png(output_png, width=14, height=6, units="in", res=150)

plot(data\$pos, data\$cov, 
     type="l", 
     col="blue",
     lwd=0.5,
     xlab="Genome Position (bp)", 
     ylab="Coverage Depth", 
     main=paste("Coverage Plot for", sample_id),
     cex.lab=1.2)

avg_cov <- mean(data\$cov)
abline(h=avg_cov, col="red", lty=2, lwd=1.5)

legend("topright", 
       legend=c(paste("Mean coverage:", round(avg_cov, 1), "x")),
       col="red", lty=2, lwd=1.5)

grid(col="gray", lty=3)

dev.off()

cat(paste("\nStatistics for", sample_id, ":\n"))
cat(paste("  Mean coverage:", round(avg_cov, 1), "x\n"))
cat(paste("  Min coverage:", min(data\$cov), "x\n"))
cat(paste("  Max coverage:", max(data\$cov), "x\n"))
EOF
    
    chmod +x plot_coverage.R
    Rscript plot_coverage.R ${id}
    """
}

workflow {
    // Getting fasta from SRA data
    sra_ch = Channel.fromSRA(params.accession)
    
    // Converting the format: [id, [r1, r2]] -> [id, r1, r2]
    reads_ch = sra_ch.map { entry -> [entry[0], entry[1][0], entry[1][1]] }
    
    // Launching processes
    FASTQC_RAW(reads_ch)
    trimmed_ch = TRIM_READS(reads_ch)
    FASTQC_TRIMMED(trimmed_ch)
    
    ref_file = file(params.reference)
    
    // MAP_READS return tuple (id, bam, bai)
    mapped_ch = MAP_READS(trimmed_ch, ref_file)
    
    // Passing tuple to PLOT_COVERAGE
    PLOT_COVERAGE(mapped_ch)
    
    log.info "Pipeline complete!!! Thank God!!!"
}
