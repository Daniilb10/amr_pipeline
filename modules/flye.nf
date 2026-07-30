process FLYE {

    tag "${meta.id}"

    cpus 4

    publishDir "${params.outdir}/assembly/flye/${meta.id}",
        mode: 'copy',
        overwrite: true

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta),
          path("${meta.id}_assembly.fasta"),
          emit: assembly

    tuple val(meta),
          path("${meta.id}_assembly_info.txt"),
          emit: info

    tuple val(meta),
          path("${meta.id}_flye.log"),
          emit: log

    script:
    """
    set -euo pipefail

    flye \
        --nano-hq "${reads}" \
        --out-dir flye_output \
        --threads ${task.cpus} \
        --genome-size ${params.genome_size}

    test -s flye_output/assembly.fasta
    test -s flye_output/assembly_info.txt

    cp flye_output/assembly.fasta \
       "${meta.id}_assembly.fasta"

    cp flye_output/assembly_info.txt \
       "${meta.id}_assembly_info.txt"

    cp flye_output/flye.log \
       "${meta.id}_flye.log"
    """
}
