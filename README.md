# AMR Oxford Nanopore Pipeline 

## Description: 
Ce projet développe un pipeline Nextflow pour l’analyse de génomes bactériens séquencés avec Oxford Nanopore et la détection de gènes de résistance aux antimicrobiens. 

## Entrées Le pipeline acceptera :
- des fichiers POD5 nécessitant un basecalling avec Dorado 
- des fichiers FASTQ déjà basecallés
- plusieurs isolats décrits dans un fichier CSV.

## Exemple de csv 

sample= identifiant de l'echantillon

input_type = Format soit POD5 ou Fastq

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
   
 8.Détection des gènes avec abricate

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
```bash git clone https://github.com/Daniilb10/amr_pipeline cd amr_pipeline ```

## Outputs:
1.Fichiers produit par le basecalling avec les données en (format: fastq.gz)

2.Fichiers QC avec les données nanoplot pour chaque échantillons (formats: html, png, txt, log)

3.Fichiers filtered avec les données filtrés par filtlong pour chaque échantillons (format: fastq.gz)

4.Dossier Flye avec fichiers pour chaque échantillons contenant l'assemblage (formats: fasta,txt,log)

5.Dossier Medaka avec fichiers pour chaque échantillons contenant l'assemblage poli (formats: bam,bai,log,hdf,fasta)

6.Dossier assembly_qc avec fichiers pour chaque échantillons contenant une évaluation de la qualité de l'assemblage (formats: pdf, html, tsv, txt)

7.Dossier Prokka avec les fichiers contenant l'annotation fonctionnelle pour chaque échantillons (formats: faa,fna,fsa,gbk,gfk,log,sqn,tbl,tsv,txt)

8.Dossier abricate avec les fichiers contenant les informations de 3 bases de données plasmidfinder,vfdb,resfinder (formats:tsv,log)






