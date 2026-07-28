process FILTLONG {

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

    if [[ "${reads}" == *.gz ]]; then
        gzip -dc "${reads}" |
        filtlong \
            --min_length ${params.min_length} \
            --keep_percent ${params.keep_percent} \
            - |
        gzip -c > "${meta.id}_filtered.fastq.gz"
    else
        filtlong \
            --min_length ${params.min_length} \
            --keep_percent ${params.keep_percent} \
            "${reads}" |
        gzip -c > "${meta.id}_filtered.fastq.gz"
    fi

    gzip -t "${meta.id}_filtered.fastq.gz"
    test -s "${meta.id}_filtered.fastq.gz"
    """
}
