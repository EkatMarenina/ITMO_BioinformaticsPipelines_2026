process TRIM_READS {
    tag "${meta.id}"
    publishDir "${params.outdir}/trimmed", mode: 'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta.id}.trimmed.fastq.gz")

    script:
    def qual = meta.qual ?: 20
    """
    fastp -i ${reads} -o ${meta.id}.trimmed.fastq.gz --qualified_quality_phred ${qual}
    """
    stub:
    """
    touch ${meta.id}.trimmed.fastq.gz
    """
}
