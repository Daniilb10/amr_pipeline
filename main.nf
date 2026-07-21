#!/usr/bin/env nextflow
 
nextflow.enable.dsl = 2 
 
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
     * Affichage temporaire des FASTQ
     */
    input_channels.fastq.view { meta, fastq ->
        """
        ------------------------------
            CANAL FASTQ
            ------------------------------
            ID       : ${meta.id}
            Type     : ${meta.input_type}
            Fichier  : ${fastq}
            ------------------------------
            """.stripIndent()
    }
    /*
     * Affichage temporaire des POD5
     */
    input_channels.pod5.view { meta, pod5 ->
        """
        ------------------------------
            CANAL POD5
            ------------------------------
            ID       : ${meta.id}
            Type     : ${meta.input_type}
            Fichier  : ${pod5}
            ------------------------------
            """.stripIndent()
    }


}

