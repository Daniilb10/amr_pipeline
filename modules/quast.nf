process QUAST {

    conda "${projectDir}/envs/quast.yml"

    tag  { "${meta.id}" }

    cpus 4

    publishDir { "${params.outdir}/assembly_qc/quast/${meta.id}" },
        mode: 'copy',
        overwrite: true

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta),
          path("${meta.id}_quast"),
          emit: report

    tuple val(meta),
          path("${meta.id}_quast/report.tsv"),
          emit: tsv

    tuple val(meta),
          path("${meta.id}_quast/report.html"),
          emit: html

    script:
    """
    set -euo pipefail

    quast  \
        "${assembly}" \
        --output-dir "${meta.id}_quast" \
        --threads ${task.cpus} \
        --min-contig ${params.quast_min_contig} \
        --labels "${meta.id}"

    test -s "${meta.id}_quast/report.tsv"
    test -s "${meta.id}_quast/report.html"
    """
}
