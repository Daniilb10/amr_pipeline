DORADO(conditionnel) -FASTQ
                      |
                  NANOPLOT
                      |
                  FILTLONG
                      |
                  NANOPLOT (APRÈS-FILTRAGE)
                      |
                  ASSEMBLAGE (FLYE)
                      |
                 QUALITÉ DE L'ASSEMBLAGE (QUAST)      
                      |
                  ANNOTATION (BAKTA)
                      |
                  AMR GÈNES (AMRFINDERPLUS)
                      |
                  Rapport Finaux (MULTIQC) et tableau recapitulatif

Entrée du pipeline:
Fichiers FASTQ, POD5, plusieurs isolat dans un fichier Samplesheet CSV

Sorties du pipeline:
- FASTQ produit par Dorado 
- rapports NanoPlot
- lectures filtrées 
- assemblage FASTA 
- résultats QUAST 
- annotation Bakta 
- résultats AMRFinderPlus 
- rapport MultiQC



