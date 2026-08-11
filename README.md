# AMR Oxford Nanopore Pipeline 
Pipeline testé avec Nextflow 24.04.4 et Java 21

## Description: 
Ce projet développe un pipeline Nextflow pour l’analyse de génomes bactériens séquencés avec Oxford Nanopore et la détection de gènes de résistance aux antimicrobiens. 

## Entrées Le pipeline acceptera :
- des fichiers POD5 nécessitant un basecalling avec Dorado 
- des fichiers FASTQ déjà basecallés
- plusieurs isolats décrits dans un fichier CSV.

## Exemple de csv 

sample= identifiant de l'echantillon

input_type = Format soit pod5 ou fastq

input = chemin vers les données 


## sample   ,  input_type  ,   input

barcode1    , fastq      ,  data/barcode01.fastq

barcode2    , fastq      ,  data/barcode02.fastq

## Étapes prévues:
1. Basecalling conditionnel avec Dorado
   
2. Contrôle qualité avec NanoPlot
   
3. Filtrage avec Filtlong
   
4. Assemblage avec Flye
   
5. Polissage avec medaka
    
6. Évaluation de l'assemblage avec QUAST
    
7. Annotation avec Prokka
   
8. Détection des gènes avec abricate

## Role du samplesheet.csv:
permettre aux utilisateurs d'entrer leurs propres fichiers csv. la colonne sample (identifiant unique de l'échantillon), la colonne input_type (fastq ou pod5), la colonne input (chemin du fichier ou dossier contenant les données).

## Avant de lancer

1. Installer Conda environments (./Install.sh)
2. Run:
   
   prokka --setupdb
   
   abricate --setupdb

4. Verifier bases de données:
   
   abricate --list
   
   bases nécessaire pour abricate: Plamidfinder,resfinder et vfdb


## Lancement actuel:
```bash nextflow run main.nf --input (chemin vers le samplesheet contenant le chemin d'accès aux données) ```


## Installation:

Nextflow >= 23.04

Conda ou Mamba

Java + 17(java -version)

## Clone:
```bash git clone https://github.com/Daniilb10/amr_pipeline ```

``` bash cd amr_pipeline ```

## Outputs:
1. Fichiers produit par le basecalling avec les données en (format: fastq.gz)

2. Fichiers QC avec les données nanoplot pour chaque échantillons (formats: html, png, txt, log)

3. Fichiers filtered avec les données filtrés par filtlong pour chaque échantillons (format: fastq.gz)

4. Dossier Flye avec fichiers pour chaque échantillons contenant l'assemblage (formats: fasta,txt,log)

5. Dossier Medaka avec fichiers pour chaque échantillons contenant l'assemblage poli (formats: bam,bai,log,hdf,fasta)

6. Dossier assembly_qc avec fichiers pour chaque échantillons contenant une évaluation de la qualité de l'assemblage (formats: pdf, html, tsv, txt)

7. Dossier Prokka avec les fichiers contenant l'annotation fonctionnelle pour chaque échantillons (formats: faa,fna,fsa,gbk,gfk,log,sqn,tbl,tsv,txt)

8. Dossier abricate avec les fichiers contenant les informations de 3 bases de données plasmidfinder,vfdb,resfinder (formats:tsv,log)

9. Rapport multiqc avec les information de nanoplot, QUAST

## Result summary

Le pipeline contient un script Python (' script/summarize_results.py') qui génere un aperçu des resultats principaux de l'annotation et de la dectection de résistance antimicrobienne.

Le script extrait et fait un résumé du :

1. Nombre de séquences codantes (CDS)
   
2. Nombre de genes condant pour de l'ARNt et ARNr

3. Nombre de proteines probables
   
4. Genes de resistance antimicrobienne AMR (unique)
   
5. Genes associés a la virulence (unique)
   
6. Marqueurs plasmidiques

Resultats de Prokka et abricate sont automatiquement regroupées par sample ID.

### Run the summary script 

Apres avoir run le pipeline, run :

```bash
python3 scripts/summarize_results.py 





-








