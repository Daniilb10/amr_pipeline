process DORADO_BASECALL {
    
    tag "${sample_id}"

    publishDir "${params.outdir}/basecall", mode: 'copy', overwrite: true

    input:
    tuple val(sample_id), path(pod5_file)

    output:
    tuple val(sample_id), path("${sample_id}.fastq.gz"),emit: reads

    script:
    """
    set -euo pipefail

    dorado basecaller \
        ${params.dorado_model} \
        ${pod5_file} \
        --threads ${task.cpus} \
        --emit-fastq \
        gzip -c > ${sample_id}.fastq.gz
    """
}