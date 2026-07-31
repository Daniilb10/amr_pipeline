# AMR Oxford Nanopore Pipeline 

## Description Ce projet développe un pipeline Nextflow pour l’analyse de génomes bactériens séquencés avec Oxford Nanopore et la détection de gènes de résistance aux antimicrobiens. 

## Entrées Le pipeline acceptera : - des fichiers POD5 nécessitant un basecalling avec Dorado ; - des fichiers FASTQ déjà basecallés ; - plusieurs isolats décrits dans un fichier CSV.

## Étapes prévues 1. Basecalling conditionnel avec Dorado 2. Contrôle qualité avec NanoPlot 3. Filtrage avec Filtlong 4. Assemblage avec Flye 5. Polissage avec medaka 6. Évaluation de l'assemblage avec QUAST 7. Annotation avec Prokka 8.Détection des gènes avec abricate

## Role du samplesheet.csv permettre aux utilisateurs d'entrer leurs propres fichiers csv. la colonne sample (identifiant unique de l'échantillon), la colonne input_type (fastq ou pod5), la colonne input (chemin du fichier ou dossier contenant les données).


## Lancement actuel ```bash nextflow run main.nf --input (chemin vers le samplesheet contenant le chemin d'accès aux données)

