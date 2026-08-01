#!/usr/bin/env bash

set -euo pipefail

echo "========================================="
echo " AMR Oxford Nanopore Pipeline Installer"
echo "========================================="

########################################
# Vérification des prérequis
########################################

for cmd in conda nextflow java; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Erreur : $cmd n'est pas installé."
        exit 1
    fi
done

echo "Pré-requis vérifiés."

########################################
# Création des environnements
########################################

echo ""
echo "Création des environnements Conda..."

for envfile in env/*.yml
do
    echo "Installation de $envfile"
    conda env create -f "$envfile" || true
done

########################################
# Initialisation Prokka
########################################

echo ""
echo "Configuration de Prokka..."

source "$(conda info --base)/etc/profile.d/conda.sh"

conda activate annotation

prokka --setupdb

conda deactivate

########################################
# Initialisation ABRicate
########################################

echo ""
echo "Téléchargement des bases ABRicate..."

conda activate detection

abricate --setupdb

echo ""
echo "Bases installées :"

abricate --list

conda deactivate

########################################
# Vérification des outils
########################################

echo ""
echo "Vérification des outils"

TOOLS=(
    NanoPlot
    filtlong
    flye
    medaka
    quast.py
    prokka
    abricate
    multiqc
)

for tool in "${TOOLS[@]}"
do
    if command -v "$tool" &>/dev/null; then
        echo "[OK] $tool"
    else
        echo "[ERREUR] $tool introuvable"
    fi
done

########################################
# Fin
########################################

echo ""
echo "========================================="
echo "Installation terminée."
echo "Vous pouvez maintenant lancer :"
echo ""
echo "nextflow run main.nf --input samplesheet.csv"
echo "========================================="
