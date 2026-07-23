process DORADO_BASECALL {

    tag "${meta.id}" 

    publishDir "${param.outdir}/basecalling",
        mode: 'copy'
        overwrite: true

    input:
    tuple val(meta), path(pod5_input)

    output:
    tuple val(meta), path("${meta.id}.fastq.gz"), emit: fastq

    script:
    """
    set -euo pipefail

    dorado basecaller \
        "${params.dorado_model}" \
        "${pod5_input}" \
        --recursive  \
        --emit-fastq \
    | gzip -c > "${meta.id}.fastq.gz"

    test -s "${meta_id}.fastq.gz"
    """
}
