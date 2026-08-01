process PROKKA {

    conda "${projectDir}/env/annotation.yml"

    tag "${meta.id}"

    publishDir "${params.outdir}/annotation/prokka/${meta.id}",
        mode: 'copy',
        overwrite: true

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta),
          path("${meta.id}_prokka/${meta.id}.gff"),
          emit: gff

    tuple val(meta),
          path("${meta.id}_prokka/${meta.id}.gbk"),
          emit: gbk

    tuple val(meta),
          path("${meta.id}_prokka/${meta.id}.faa"),
          emit: proteins

    tuple val(meta),
          path("${meta.id}_prokka/${meta.id}.ffn"),
          emit: genes

    tuple val(meta),
          path("${meta.id}_prokka/${meta.id}.fna"),
          emit: nucleotide

    tuple val(meta),
          path("${meta.id}_prokka/${meta.id}.tsv"),
          emit: tsv

    tuple val(meta),
          path("${meta.id}_prokka"),
          emit: results

    script:
    def genusOption   = params.prokka_genus   ? "--genus '${params.prokka_genus}'"     : ''
    def speciesOption = params.prokka_species ? "--species '${params.prokka_species}'" : ''
    def strainOption  = params.prokka_strain  ? "--strain '${params.prokka_strain}'"   : ''

    """
    set -euo pipefail

    prokka \
        "${assembly}" \
        --outdir "${meta.id}_prokka" \
        --prefix "${meta.id}" \
        --locustag "${meta.id.toUpperCase().replaceAll(/[^A-Z0-9]/, '')}" \
        --cpus ${task.cpus} \
        --kingdom "${params.prokka_kingdom}" \
        ${genusOption} \
        ${speciesOption} \
        ${strainOption} \
        --force

    test -s "${meta.id}_prokka/${meta.id}.gff"
    test -s "${meta.id}_prokka/${meta.id}.gbk"
    test -s "${meta.id}_prokka/${meta.id}.faa"
    test -s "${meta.id}_prokka/${meta.id}.ffn"
    test -s "${meta.id}_prokka/${meta.id}.fna"
    test -s "${meta.id}_prokka/${meta.id}.tsv"
    """
}
