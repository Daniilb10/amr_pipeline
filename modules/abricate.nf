process ABRICATE {

    conda "${projectDir}/envs/detection.yml"

    tag "${meta.id}"

    publishDir "${params.outdir}/detection/abricate/${meta.id}",
        mode: 'copy',
        overwrite: true

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta),
          path("${meta.id}_resfinder.tsv"),
          emit: resistance

    tuple val(meta),
          path("${meta.id}_vfdb.tsv"),
          emit: virulence

    tuple val(meta),
          path("${meta.id}_plasmidfinder.tsv"),
          emit: plasmids

    tuple val(meta),
          path("${meta.id}_abricate_combined.tsv"),
          emit: combined

    tuple val(meta),
          path("${meta.id}_abricate_summary.tsv"),
          emit: summary

    path "${meta.id}_abricate.log",
         emit: log

    script:
    """
    set -euo pipefail

    : > "${meta.id}_abricate.log"

    echo "ABRicate resistance analysis: resfinder" \
        >> "${meta.id}_abricate.log"

    abricate \
        --db "${params.abricate_amr_db}" \
        --minid ${params.abricate_min_identity} \
        --mincov ${params.abricate_min_coverage} \
        --threads ${task.cpus} \
        "${assembly}" \
        > "${meta.id}_resfinder.tsv" \
        2>> "${meta.id}_abricate.log"

    echo "ABRicate virulence analysis: vfdb" \
        >> "${meta.id}_abricate.log"

    abricate \
        --db "${params.abricate_virulence_db}" \
        --minid ${params.abricate_min_identity} \
        --mincov ${params.abricate_min_coverage} \
        --threads ${task.cpus} \
        "${assembly}" \
        > "${meta.id}_vfdb.tsv" \
        2>> "${meta.id}_abricate.log"

    echo "ABRicate plasmid replicon analysis: plasmidfinder" \
        >> "${meta.id}_abricate.log"

    abricate \
        --db "${params.abricate_plasmid_db}" \
        --minid ${params.abricate_min_identity} \
        --mincov ${params.abricate_min_coverage} \
        --threads ${task.cpus} \
        "${assembly}" \
        > "${meta.id}_plasmidfinder.tsv" \
        2>> "${meta.id}_abricate.log"

    /*
     * Fusion des résultats :
     * - un seul en-tête ;
     * - ajout de la colonne ANALYSIS_TYPE ;
     * - suppression des en-têtes répétés.
     */
    awk -F '\\t' -v OFS='\\t' '
        BEGIN {
            print "ANALYSIS_TYPE",
                  "#FILE",
                  "SEQUENCE",
                  "START",
                  "END",
                  "STRAND",
                  "GENE",
                  "COVERAGE",
                  "COVERAGE_MAP",
                  "GAPS",
                  "%COVERAGE",
                  "%IDENTITY",
                  "DATABASE",
                  "ACCESSION",
                  "PRODUCT",
                  "RESISTANCE"
        }

        FNR > 1 && NF > 1 {
            print "AMR", \$0
        }
    ' "${meta.id}_resfinder.tsv" \
        > "${meta.id}_abricate_combined.tsv"

    awk -F '\\t' -v OFS='\\t' '
        FNR > 1 && NF > 1 {
            print "VIRULENCE", \$0
        }
    ' "${meta.id}_vfdb.tsv" \
        >> "${meta.id}_abricate_combined.tsv"

    awk -F '\\t' -v OFS='\\t' '
        FNR > 1 && NF > 1 {
            print "PLASMID_REPLICON", \$0
        }
    ' "${meta.id}_plasmidfinder.tsv" \
        >> "${meta.id}_abricate_combined.tsv"

    abricate --summary \
        "${meta.id}_resfinder.tsv" \
        "${meta.id}_vfdb.tsv" \
        "${meta.id}_plasmidfinder.tsv" \
        > "${meta.id}_abricate_summary.tsv" \
        2>> "${meta.id}_abricate.log"

    test -s "${meta.id}_resfinder.tsv"
    test -s "${meta.id}_vfdb.tsv"
    test -s "${meta.id}_plasmidfinder.tsv"
    test -s "${meta.id}_abricate_combined.tsv"
    test -s "${meta.id}_abricate_summary.tsv"
    """
}
