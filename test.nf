nextflow.enable.dsl = 2

process TEST {
    tag "${meta.id}"
    publishDir "output/${meta.stage}", mode: 'copy'

    input:
    tuple val(meta), path(f)

    output:
    path "*.txt"

    script:
    """
    echo "hello" > ${meta.id}.txt
    """
}

workflow {
    ch = Channel.of([[id: "sample1", stage: "raw"], file("$baseDir/main.nf")])
    TEST(ch)
}
