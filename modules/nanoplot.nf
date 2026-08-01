process NANOPLOT_RAW {

    conda "${projectDir}/envs/qc.yml"

    tag "${meta.id}"

    cpus 4

    publishDir "${params.outdir}/qc/nanoplot_raw",
        mode: 'copy',
        overwrite: true

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta),
          path("${meta.id}_nanoplot_raw"),
          emit: report

    script:
    """
    set -euo pipefail

    NanoPlot \
        --fastq "${reads}" \
        --outdir "${meta.id}_nanoplot_raw" \
        --threads ${task.cpus} \
        --prefix "${meta.id}_"

    test -s "${meta.id}_nanoplot_raw/${meta.id}_NanoStats.txt"
    """
}
