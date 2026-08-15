# AMR Oxford Nanopore Pipeline 

## Description: 
Ce projet développe un pipeline Nextflow pour l’analyse de génomes bactériens séquencés avec Oxford Nanopore et la détection de gènes de résistance aux antimicrobiens. 

## Entrées Le pipeline acceptera :
- des fichiers POD5 nécessitant un basecalling avec Dorado 
- des fichiers FASTQ déjà basecallés
- plusieurs isolats décrits dans un fichier CSV.

## structure du samplesheet 

| Colonne      | Description                                                | Valeur attendue            |
| ------------ | ---------------------------------------------------------- | -------------------------- |
| `sample`     | Identifiant unique de l'échantillon                        | ex. `barcode1`             |
| `input_type` | Type de données d'entrée                                   | `pod5` ou `fastq`          |
| `input`      | Chemin vers le fichier ou le dossier contenant les données | ex. `data/barcode01.fastq` |

## exemple de samplesheet

sample,input_type,input

barcode1,fastq,data/barcode01.fastq

barcode2,fastq,data/barcode02.fastq



## Role du samplesheet

Le fichier samplesheet.csv permet aux utilisateurs de fournir leurs propres données au pipeline.

Chaque ligne correspond à un échantillon et doit contenir :

sample : identifiant unique de l'échantillon ;
input_type : type de données, soit fastq, soit pod5 ;
input : chemin vers le fichier FASTQ ou vers le dossier contenant les fichiers POD5.

Le pipeline détermine automatiquement le workflow à utiliser en fonction de la valeur de input_type.

## Etapes du pipeline

Les principales étapes du pipeline sont :

1. Basecalling conditionnel avec Dorado:
Exécuté uniquement lorsque les données d'entrée sont au format POD5.

2. Contrôle qualité avec NanoPlot:
Évaluation de la qualité des lectures brutes.

3. Filtrage avec Filtlong:
Suppression des lectures de mauvaise qualité.

4. Contrôle qualité après filtrage avec NanoPlot:
Évaluation de la qualité des lectures après filtrage.

5. Assemblage avec Flye:
Assemblage de novo du génome bactérien.

6. Polissage avec Medaka:
Amélioration de la qualité de l'assemblage.

7. Évaluation de l'assemblage avec QUAST:
Analyse de la qualité et des statistiques de l'assemblage.

8. Annotation avec Prokka:
Annotation fonctionnelle du génome assemblé.

9. Détection des gènes avec ABRicate:
Détection des gènes de résistance aux antimicrobiens ;
Détection des gènes de virulence ;
Détection des marqueurs plasmidiques.

10. Agrégation des résultats avec MultiQC:
Génération d'un rapport regroupant les résultats de contrôle qualité et d'évaluation des assemblages.


## Avant de lancer

1. Installer Conda environments (./Install.sh)
   
2. Initialiser les bases de données
   
   prokka --setupdb
   
   abricate --setupdb

3. Verifier bases de données:
   
   abricate --list
   
   bases nécessaire pour abricate: Plamidfinder,resfinder et vfdb

## Installation prérequis 
Le pipeline nécessite :

Nextflow >= 23.04
Java 21
Conda ou Mamba

La version de Java peut être vérifiée avec :

java -version

Le pipeline a été testé avec :

Plusieurs versions de Nextflow

## Cloner le dépot:

``` git clone https://github.com/Daniilb10/amr_pipeline ```

```  cd amr_pipeline ```

## Lancement actuel:

Le pipeline peut être lancé avec :

``` nextflow run main.nf --input (chemin vers le samplesheet contenant le chemin d'accès aux données) ```

Par exemple :

```nextflow run main.nf --input test_data/samplesheet_test_fastq.csv ```

Pour reprendre une exécution interrompue ou réutiliser les processus déjà terminés :

```
nextflow run main.nf \
    --input test_data/samplesheet_test_fastq.csv \
    -resume
```

## Tester le pipeline avec le jeu de données fastq fourni

Un petit jeu de données FASTQ d'Oxford Nanopore est fourni dans le répertoire test_data/. Ce jeu de données permet de vérifier que le pipeline est correctement installé et que les principales étapes d'analyse s'exécutent correctement.

Ce jeu de données est destiné principalement à la validation technique du pipeline et non à une analyse biologique complète.

## Structure des données test

Le répertoire de test devrait contenir :

test_data/

test_barcode01.fastq.gz

test_barcode02.fastq.gz

samplesheet_test_fastq.csv

## Sampesheet de test 

Le fichier test_data/samplesheet_test_fastq.csv contient les échantillons ainsi que leurs fichiers FASTQ correspondants.

Exemple :

sample,input_type,input

test_barcode01,fastq,test_data/test_barcode01.fastq.gz

test_barcode02,fastq,test_data/test_barcode02.fastq.gz


Les colonnes sont les mêmes que celles décrites dans la section Entrées 

Les fichiers FASTQ peuvent être compressés (.fastq.gz) ou non compressés (.fastq), selon la configuration du pipeline.


## Exécuter le test

Depuis le répertoire racine du dépôt :

```
nextflow run main.nf \
    --input test_data/samplesheet_test_fastq.csv
```

Pour reprendre une exécution précédente :

```
nextflow run main.nf \
    --input test_data/samplesheet_test_fastq.csv \
    -resume

```
## workflow attendu pour des donnés fastq

Comme les données de test sont déjà au format FASTQ, Dorado n'est pas exécuté.

Le pipeline doit automatiquement démarrer directement à partir de l'analyse FASTQ :

| Étape | Outil                        | Fonction                                                   | Résultat principal              |
| ----- | ---------------------------- | ---------------------------------------------------------- | ------------------------------- |
| 1     | **FASTQ**                    | Données d'entrée déjà basecallées                          | Fichiers `.fastq` / `.fastq.gz` |
| 2     | **NanoPlot**                 | Contrôle qualité des lectures brutes                       | Rapports QC                     |
| 3     | **Filtlong**                 | Filtrage des lectures de mauvaise qualité                  | FASTQ filtrés                   |
| 4     | **NanoPlot**                 | Contrôle qualité après filtrage                            | Rapports QC filtrés             |
| 5     | **Flye**                     | Assemblage *de novo* du génome                             | Assemblage `.fasta`             |
| 6     | **Medaka**                   | Polissage de l'assemblage                                  | Assemblage poli                 |
| 7     | **QUAST**                    | Évaluation de la qualité de l'assemblage                   | Rapports d'évaluation           |
| 8     | **Prokka**                   | Annotation fonctionnelle du génome                         | Fichiers d'annotation           |
| 9     | **ABRicate – ResFinder**     | Détection des gènes de résistance aux antimicrobiens (AMR) | Résultats AMR                   |
| 10    | **ABRicate – VFDB**          | Détection des gènes/facteurs de virulence                  | Résultats de virulence          |
| 11    | **ABRicate – PlasmidFinder** | Détection des marqueurs plasmidiques                       | Résultats plasmidiques          |
| 12    | **MultiQC**                  | Agrégation des résultats QC                                | Rapport HTML final              |


## Validation du test:

Une exécution réussie du jeu de données de test doit permettre de vérifier que les principales étapes du pipeline fonctionnent correctement :

1. lecture des fichiers FASTQ ;
2. contrôle qualité avec NanoPlot ;
3. filtrage avec Filtlong ;
4. assemblage avec Flye ;
5. polissage avec Medaka ;
7. évaluation avec QUAST ;
8. annotation avec Prokka ;
9. détection des gènes avec ABRicate ;
10. génération du rapport MultiQC ;
11. génération des fichiers de résumé.

Le jeu de données de test étant réduit, les statistiques d'assemblage et les résultats biologiques peuvent différer de ceux obtenus avec un jeu de données complet provenant d'un séquençage Oxford Nanopore.

La réussite du test confirme principalement que le pipeline, ses processus et ses dépendances sont correctement installés et fonctionnels.

## outputs

Après une exécution réussie, les principaux résultats sont disponibles dans le répertoire :

results/

Selon la configuration du pipeline, les résultats peuvent inclure les éléments suivants:

| N° | Résultat / Étape                           | Outil                    | Description                                                                                                                           | Principaux fichiers / formats                                                  |
| -: | ------------------------------------------ | ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
|  1 | **Basecalling**                            | Dorado                   | Conversion des données POD5 en séquences FASTQ. Cette étape est uniquement exécutée lorsque les données d'entrée sont au format POD5. | `.fastq.gz`                                                                    |
|  2 | **Contrôle qualité des lectures brutes**   | NanoPlot                 | Évaluation de la qualité des lectures avant filtrage.                                                                                 | `.html`, `.png`, `.txt`, `.log`                                                |
|  3 | **Lectures filtrées**                      | Filtlong                 | Filtrage des lectures selon les critères de qualité définis dans le pipeline.                                                         | `.fastq.gz`                                                                    |
|  4 | **Contrôle qualité des lectures filtrées** | NanoPlot                 | Évaluation de la qualité des lectures après filtrage.                                                                                 | `.html`, `.png`, `.txt`, `.log`                                                |
|  5 | **Assemblage du génome**                   | Flye                     | Assemblage *de novo* des lectures filtrées afin de reconstruire le génome bactérien.                                                  | `.fasta`, `.txt`, `.log`                                                       |
|  6 | **Polissage de l'assemblage**              | Medaka                   | Amélioration de la précision de l'assemblage obtenu avec Flye.                                                                        | `.bam`, `.bai`, `.log`, `.hdf`, `.fasta`                                       |
|  7 | **Évaluation de l'assemblage**             | QUAST                    | Évaluation de la qualité et des principales statistiques de l'assemblage.                                                             | `.pdf`, `.html`, `.tsv`, `.txt`                                                |
|  8 | **Annotation fonctionnelle**               | Prokka                   | Annotation des séquences codantes, ARN et autres éléments génomiques.                                                                 | `.faa`, `.fna`, `.fsa`, `.gbk`, `.gff`, `.log`, `.sqn`, `.tbl`, `.tsv`, `.txt` |
|  9 | **Détection des gènes AMR**                | ABRicate / ResFinder     | Identification des gènes de résistance aux antimicrobiens.                                                                            | `.tsv`, `.log`                                                                 |
| 10 | **Détection des gènes de virulence**       | ABRicate / VFDB          | Identification des gènes et facteurs associés à la virulence.                                                                         | `.tsv`, `.log`                                                                 |
| 11 | **Détection des marqueurs plasmidiques**   | ABRicate / PlasmidFinder | Identification des marqueurs associés aux plasmides.                                                                                  | `.tsv`, `.log`                                                                 |
| 12 | **Agrégation des résultats**               | MultiQC                  | Regroupement des résultats de contrôle qualité et d'évaluation provenant notamment de NanoPlot et QUAST.                              | `.html`                                                                        |



### Result summary 

Le pipeline contient un script Python :

scripts/summarize_results.py

Ce script génère un aperçu des principaux résultats d'annotation et de détection des résistances aux antimicrobiens.

Le script extrait et résume notamment :

le nombre de séquences codantes (CDS) ;
le nombre de gènes codant pour des ARNt et ARNr ;
le nombre de protéines probables ;
les gènes de résistance aux antimicrobiens (AMR) uniques ;
les gènes associés à la virulence uniques ;
les marqueurs plasmidiques.

Les résultats de Prokka et ABRicate sont automatiquement regroupés par identifiant d'échantillon (sample ID).

## Exécuter le script de résumé:

Après avoir exécuté le pipeline, lancer : 

```
python3 scripts/summarize_results.py


```









