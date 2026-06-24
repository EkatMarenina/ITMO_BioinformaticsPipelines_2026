process FASTQC {
    tag "${meta.id}"
    publishDir "${params.outdir}/fastqc", mode: 'copy'

    input:
    tuple val(meta), path(r1), path(r2)

    output:
    path "*.html"

    script:
    def prefix = meta.stage
    """
    fastqc ${r1} ${r2} --noextract
    for f in *.html; do mv "\$f" "${prefix}_\$f"; done
    """
}
