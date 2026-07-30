process AMRFINDER {

    tag "${meta.id}"

    publishDir "${params.outdir}/amr/amrfinder/${meta.id}",
        mode: 'copy',
        overwrite: true

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta),
          path("${meta.id}_amrfinder.tsv"),
          emit: all_results

    tuple val(meta),
          path("${meta.id}_amr.tsv"),
          emit: amr

    tuple val(meta),
          path("${meta.id}_virulence.tsv"),
          emit: virulence

    tuple val(meta),
          path("${meta.id}_stress.tsv"),
          emit: stress

    path "${meta.id}_amrfinder.log",
         emit: log

    script:
    def organismOption = params.amrfinder_organism
        ? "--organism '${params.amrfinder_organism}'"
        : ''

    """
    set -euo pipefail

    amrfinder \
        --nucleotide "${assembly}" \
        --plus \
        ${organismOption} \
        --threads ${task.cpus} \
        --output "${meta.id}_amrfinder.tsv" \
        > "${meta.id}_amrfinder.log" 2>&1

    test -s "${meta.id}_amrfinder.tsv"

    # Conserver l'en-tête et séparer selon la colonne Element type.
    awk -F '\\t' '
        NR == 1 || \$0 ~ /AMR/
    ' "${meta.id}_amrfinder.tsv" \
        > "${meta.id}_amr.tsv"

    awk -F '\\t' '
        NR == 1 || \$0 ~ /VIRULENCE/
    ' "${meta.id}_amrfinder.tsv" \
        > "${meta.id}_virulence.tsv"

    awk -F '\\t' '
        NR == 1 || \$0 ~ /STRESS/
    ' "${meta.id}_amrfinder.tsv" \
        > "${meta.id}_stress.tsv"
    """
}
