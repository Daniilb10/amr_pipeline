#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

workflow {

    /*
     * Vérification du paramètre --input
     */
    if (!params.input) {
        error """
        Aucun samplesheet n'a été fourni.

        Utilisation :
        nextflow run main.nf \
            --input assets/samplesheet.example.csv
        """
    }

    /*
     * Création d'un canal contenant le fichier CSV
     */
    samplesheet_ch = Channel
        .fromPath(params.input, checkIfExists: true)

    /*
     * Lecture du fichier CSV
     */
    samples_ch = samplesheet_ch
        .splitCsv(header: true)

    /*
     * Affichage de chaque ligne
     */
    samples_ch.view { row ->
        "Échantillon lu : ${row}"
    }
}