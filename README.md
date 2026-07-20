# AMR Oxford Nanopore Pipeline 

## Description Ce projet développe un pipeline Nextflow pour l’analyse de génomes bactériens séquencés avec Oxford Nanopore et la détection de gènes de résistance aux antimicrobiens. 

## Entrées Le pipeline acceptera : - des fichiers POD5 nécessitant un basecalling avec Dorado ; - des fichiers FASTQ déjà basecallés ; - plusieurs isolats décrits dans un fichier CSV.

## Étapes prévues 1. Basecalling conditionnel avec Dorado 2. Contrôle qualité avec NanoPlot 3. Filtrage avec Filtlong 4. Assemblage avec Flye 5. Évaluation avec QUAST 6. Annotation avec Bakta 7. Détection AMR avec AMRFinderPlus 8. Rapport final avec MultiQC 

## Lancement actuel ```bash nextflow run main.nf
