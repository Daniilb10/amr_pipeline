process FILTLONG {

    conda "${projectDir}/envs/qc.yml"

    tag "${meta.id}"

    cpus 4

    publishDir "${params.outdir}/filtered",
        mode: 'copy',
        overwrite: true

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta),
          path("${meta.id}_filtered.fastq.gz"),
          emit: reads

    script:
    """
    set -euo pipefail

        filtlong \
            --min_length ${params.min_length} \
            --keep_percent ${params.keep_percent} \
            "${reads}" |
        gzip -c > "${meta.id}_filtered.fastq.gz"

    gzip -t "${meta.id}_filtered.fastq.gz"
    test -s "${meta.id}_filtered.fastq.gz"
    """
}
