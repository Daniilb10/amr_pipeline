DORADO(conditionnel) -FASTQ
                      |
                  NANOPLOT
                      |
                  FILTLONG
                      |
                  ASSEMBLAGE (FLYE)
                      |
                 QUALITÉ DE L'ASSEMBLAGE (QUAST)      
                      |
                  ANNOTATION (Prokka)
                      |
                  AMR GÈNES (ABRICATE)
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
- annotation Prokka
- résultats Abricate
- rapport MultiQC



