#!/usr/bin/env nextflow
 
nextflow.enable.dsl = 2 

include { DORADO_BASECALL } from './modules/dorado_basecall'
include { NANOPLOT_RAW } from './modules/nanoplot'
include { FILTLONG } from './modules/filtlong'
include { FLYE }  from './modules/flye'
include { MEDAKA } from './modules/medaka'
include { PROKKA } from './modules/prokka'
 
 def validateSample(row) { 

    def sampleId = row.sample?.toString()?.trim()
    def inputType = row.input_type?.toString()?.trim()?.toLowerCase()
    def inputValue = row.input?.toString()?.trim() 

    if (!sampleId) { 
        error """ 
        ERREUR DANS LE SAMPLESHEET : 
        la colonne 'sample' est vide. 
        
        Ligne : 
        ${row}
        """ 
    } 

    if (!(sampleId ==~ /[A-Za-z0-9][A-Za-z0-9_.-]*/)) { 
            error """ 
            ERREUR DANS LE SAMPLESHEET : identifiant invalide '${sampleId}'.
             """
    } 
             
    if (!inputType) { 
            error """ 
            ERREUR DANS LE SAMPLESHEET : 'input_type' est vide pour '${sampleId}'. 
            """ 
    } 
            
    if (!(inputType in ['fastq', 'pod5'])) { 
        error """
        ERREUR DANS LE SAMPLESHEET : 
        input_type '${inputType}' invalide pour '${sampleId}'.
         
        Valeurs autorisées : fastq ou pod5.
         """
    } 
                  
    if (!inputValue) { 
        error """ 
        ERREUR DANS LE SAMPLESHEET : 
        le chemin 'input' est vide pour '${sampleId}'.
        """ 
    } 
                 
     def inputPath = file(inputValue, checkIfExists: true)
                  
    if (inputType == 'fastq') { 

    if (!inputPath.isFile()) { 
        error """ 
        ERREUR :
        l'entrée FASTQ de '${sampleId}' n'est pas un fichier.
                         
        Chemin : ${inputPath}                  
        """ 
    } 

    def filename = inputPath.getName().toLowerCase() 
                 
    if (!(filename.endsWith('.fastq') || 
          filename.endsWith('.fastq.gz') || 
          filename.endsWith('.fq') || 
          filename.endsWith('xz')  || 
          filename.endsWith('.fq.gz'))) { 
                        
                        
        error """
        ERREUR :
        extension FASTQ invalide pour '${sampleId}'. 
                         
        Fichier : ${inputPath} 
        """ 
    } 

} 
                 
if (inputType == 'pod5') { 
                    
    if (!(inputPath.isDirectory() || inputPath.isFile())) { 
        error """
        ERREUR : 
        l'entrée POD5 de '${sampleId}' est invalide.
                         
        Chemin : ${inputPath}
        """
    } 
                         
    if (inputPath.isFile() && 
        !inputPath.getName().toLowerCase().endsWith('.pod5')) {
                            
        error """
        ERREUR : 
        le fichier de '${sampleId}' ne possède pas
        l'extension .pod5.
                        
        Fichier : ${inputPath}
        """ 
    } 
} 
                
                
def meta = [ 
    id : sampleId,
    input_type : inputType 
] 
                    
return tuple(meta, inputPath) 
             
} 
             
 
 workflow { 
    
    if (!params.input) {
        error """ 
        Aucun samplesheet n'a été fourni.
        
        Utilisation : 
        nextflow run main.nf \
            --input assets/samplesheet.example.csv 
          """ 
        } 
        
    if (!params.input.toString().toLowerCase().endsWith('.csv')) { 
        error """
        Le paramètre --input doit désigner un fichier CSV. 
             
        Valeur reçue :
        ${params.input}
        """ 
    } 
        /*
         * Lecture du samplesheet et validation des entrées
         */
    samples_ch = channel
        .fromPath(params.input, checkIfExists: true) 
        .splitCsv(header: true) 
        .map { row -> validateSample(row) 
        } 

    /*
     * Séparation des entrées selon les input_type (fastq ou pod5) pour les traiter différemment
     */
    input_channels = samples_ch.branch { meta, input_file ->
        fastq: meta.input_type == 'fastq'
        pod5: meta.input_type == 'pod5'
    }

   /*
    * Basecalling seulement pour les fichiers pod5
    */
   DORADO_BASECALL(input_channel.pod5)

    /*
     * FASTQ déjà basecallés
     */
    direct_fastq_ch = input_channels.fastq.map { meta, fastq ->

        def updated_meta = meta + [
            source: 'samplesheet'
        ]

        tuple(updated_meta, fastq)
    }
    
    /*
     * FASTQ produits par Dorado
     */
    dorado_fastq_ch = DORADO_BASECALL.out.fastq.map { meta, fastq ->

        def updated_meta = meta + [
            source: 'dorado'
        ]

        tuple(updated_meta, fastq)
    }

    /*
     * Réunion de tous les FASTQ dans un seul canal
     */
    reads_ch = direct_fastq_ch.mix(dorado_fastq_ch)

    /*
     * Contrôle qualité NanoPlot
     */
    NANOPLOT_RAW(reads_ch)

    /*
     * Filtration
     */
    FILTLONG(reads_ch)

    /*
     * FILTLONG.out.reads doit produire :
     * tuple(meta, filtered_fastq)
     */
    filtered_qc_ch = FILTLONG.out.reads.map { meta, reads ->
        tuple(meta, reads, 'filtered')
    }

    /*
     * Assemblage de novo
     */
    FLYE(FILTLONG.out.reads)

   /*
    * Préparation des lectures filtrées pour la jointure
    */
   filtered_for_medaka_ch = FILTLONG.out.reads.map { meta, reads ->
       tuple(meta.id, meta, reads)
    }

    /*
     * Préparation des assemblages Flye pour la jointure
     */
      assembly_for_medaka_ch = FLYE.out.assembly.map { meta, assembly ->
        tuple(meta.id, assembly)
      }

     /*
      * Association par sample ID
      */
      medaka_input_ch = filtered_for_medaka_ch
         .join(assembly_for_medaka_ch)
         .map { sample_id, meta, reads, assembly ->
                tuple(meta, reads, assembly)
    }

    /*
     * Polissage Medaka
     */
    MEDAKA(medaka_input_ch)


    /*
     * Affichage temporaire 
     */
    FLYE.out.assembly.view { meta, assembly ->
        """
        ------------------------------
            ASSENBLAGE FLYE TERMINE
            ------------------------------
            Echantillon    : ${meta.id}
            Assemblage   : ${assembly}
            ------------------------------
            """.stripIndent()
    }
    



}

