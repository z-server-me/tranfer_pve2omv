#!/bin/bash

# Variables
SOURCE_DIR_AN="/serie_music/anime"
DEST_DIR_ANIME="/mnt/pve/TVshows/Anime"

SOURCE_DIR_SE="/serie_music/serie"
DEST_DIR_SERIE="/mnt/pve/TVshows/Serie"

SOURCE_DIR_MU="/serie_music/music"
DEST_DIR_MUSIC="/mnt/pve/Music"

LOCK_FILE="/tmp/pve2omvtransfert.lock"  # Fichier de verrouillage

# Initialiser rapport
REPORT="=== Rapport de Transfert ===\n"

# Fonction pour traiter un couple source/destination
transfer_files() {
    local SOURCE_DIR=$1
    local DEST_DIR=$2
    local LABEL=$3  # ex: "Anime", "Série", etc.

    # Vérifier si le répertoire source existe
    if [ ! -d "$SOURCE_DIR" ]; then
        REPORT+="❌ $LABEL : Le répertoire source $SOURCE_DIR n'existe pas.\n"
        return
    fi

    # Vérifier s'il y a des fichiers
    if [ -z "$(ls -A "$SOURCE_DIR")" ]; then
        REPORT+="ℹ️  $LABEL : Aucun fichier à transférer.\n"
        return
    fi

    echo "🛠️ Début de la copie des fichiers de $SOURCE_DIR vers $DEST_DIR."

    # Créer le répertoire de destination s'il n'existe pas
    mkdir -p "$DEST_DIR"

    # Copie avec rsync (avec gestion d'encodage pour musique)
    if [ "$LABEL" == "Musique" ]; then
        rsync -av --iconv=utf-8-mac,utf-8 --progress "$SOURCE_DIR/" "$DEST_DIR/" &> /tmp/rsync_music.log
    else
        rsync -av --progress "$SOURCE_DIR/" "$DEST_DIR/"
    fi

    if [ $? -ne 0 ]; then
        REPORT+="❌ $LABEL : La copie a échoué.\n"
        return
    fi

    # Suppression des fichiers source
    rm -r "$SOURCE_DIR"/*
    if [ $? -ne 0 ]; then
        REPORT+="⚠️ $LABEL : Copie OK mais échec suppression source.\n"
        return
    fi

    # Mise à jour des permissions et propriétaire
    chmod -R 777 "$DEST_DIR" || { REPORT+="⚠️ $LABEL : Échec chmod.\n"; return; }
    chown -R 911:911 "$DEST_DIR" || { REPORT+="⚠️ $LABEL : Échec chown.\n"; return; }

    # Correction des erreurs résiduelles
    find "$DEST_DIR" ! -perm 777 -exec chmod 777 {} \;
    find "$DEST_DIR" ! -user 911 ! -group 911 -exec chown 911:911 {} \;

    # Résumé du transfert
    NB_FILES=$(find "$DEST_DIR" -type f | wc -l)
    REPORT+="✅ $LABEL : Transfert terminé avec $NB_FILES fichiers.\n"
}

# Vérifier verrou
if [ -e "$LOCK_FILE" ]; then
    echo "❌ Le script est déjà en cours d'exécution. Fichier de verrouillage détecté."
    exit 1
fi

touch "$LOCK_FILE"

# Traitement des transferts
transfer_files "$SOURCE_DIR_AN" "$DEST_DIR_ANIME" "Anime"
transfer_files "$SOURCE_DIR_SE" "$DEST_DIR_SERIE" "Série"
transfer_files "$SOURCE_DIR_MU" "$DEST_DIR_MUSIC" "Musique"

# Nettoyage
rm -f "$LOCK_FILE"

# Afficher rapport
echo -e "$REPORT"
