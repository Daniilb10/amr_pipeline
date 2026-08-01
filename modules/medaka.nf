process MEDAKA {

    conda "${projectDir}/envs/polishing.yml"

    tag "${meta.id}"

    cpus 4

    publishDir "${params.outdir}/polishing/medaka/${meta.id}",
        mode: 'copy',
        overwrite: true

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta),
          path("${meta.id}_medaka_consensus.fasta"),
          emit: consensus

    tuple val(meta),
          path("${meta.id}_medaka_calls.hdf"),
          emit: calls

    tuple val(meta),
          path("${meta.id}_medaka.bam"),
          path("${meta.id}_medaka.bam.bai"),
          emit: alignment

    path "${meta.id}_medaka.log",
         emit: log

    script:
    """
    set -euo pipefail

    medaka_consensus \
        -i "${reads}" \
        -d "${assembly}" \
        -o medaka_output \
        -t ${task.cpus} \
        -m "${params.medaka_model}" \
        > "${meta.id}_medaka.log" 2>&1

    test -s medaka_output/consensus.fasta
    test -s medaka_output/consensus_probs.hdf
    test -s medaka_output/calls_to_draft.bam
    test -s medaka_output/calls_to_draft.bam.bai

    cp medaka_output/consensus.fasta \
       "${meta.id}_medaka_consensus.fasta"

    cp medaka_output/consensus_probs.hdf \
       "${meta.id}_medaka_calls.hdf"

    cp medaka_output/calls_to_draft.bam \
       "${meta.id}_medaka.bam"

    cp medaka_output/calls_to_draft.bam.bai \
       "${meta.id}_medaka.bam.bai"
    """
}
