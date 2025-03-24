# 📂 Script de Transfert PVE → OMV

Ce script bash automatise le transfert de fichiers depuis des répertoires locaux sur un serveur **Proxmox VE** (`/serie_music/...`) vers un NAS distant monté en **NFS** (via `/mnt/pve/...`, exporté par OMV).

Il traite trois catégories : **Anime**, **Série** et **Musique**, en prenant en charge les permissions, les problèmes d'encodage, et en générant un rapport détaillé.

---

## 🛠️ Fonctionnalités

- 📁 **Transfert automatique** des fichiers avec `rsync`
- ✅ **Vérification des répertoires** source et destination
- 🔐 **Système de verrouillage** pour éviter les exécutions simultanées
- 🧹 **Suppression des fichiers sources** après copie réussie
- 🔧 **Réglage des permissions** (`chmod 777`, `chown 911:911`)
- 🧾 **Rapport de transfert** affiché à la fin
- 📝 **Log dédié pour la musique** en cas d’erreur (`/tmp/rsync_music.log`)

---

## 📂 Structure des répertoires

| Catégorie | Source (PVE)            | Destination (OMV via NFS)       |
|-----------|--------------------------|----------------------------------|
| Anime     | `/serie_music/anime`     | `/mnt/pve/TVshows/Anime`        |
| Série     | `/serie_music/serie`     | `/mnt/pve/TVshows/Serie`        |
| Musique   | `/serie_music/music`     | `/mnt/pve/Music`                |

---

## 🚀 Exécution

```bash
bash transfert_anime-music-serie.sh
```

⚠️ Si un transfert est déjà en cours, le script refusera de s'exécuter (grâce à un fichier de verrou `/tmp/pve2omvtransfert.lock`).

---

## 📆 Dépendances

- `rsync`
- `bash`
- Accès à `/mnt/pve/...` (ex : NFS monté depuis OMV)
- Utilisateur ayant les droits de lecture sur les dossiers source et d’écriture sur les dossiers de destination

---

## 🛡️ Gestion des erreurs

- Si un répertoire source est vide ou inexistant ➔ info dans le rapport.
- Si `rsync` échoue (notamment sur des caractères spéciaux en musique), les erreurs sont loggées dans :
  
  ```
  /tmp/rsync_music.log
  ```

- Le script ne supprime les fichiers sources **qu’en cas de succès** de la copie.

---

## 🧹 Nettoyage automatique

- Le fichier de verrou (`/tmp/pve2omvtransfert.lock`) est supprimé automatiquement à la fin de l'exécution.
- En cas d’arrêt brutal, il peut rester et bloquer la relance : dans ce cas, supprime-le manuellement :

  ```bash
  rm -f /tmp/pve2omvtransfert.lock
  ```

---

## 🔄 Relancer uniquement une catégorie

Pour relancer uniquement la musique par exemple :

```bash
bash -c '. ./transfert_anime-music-serie.sh; transfer_files "/serie_music/music" "/mnt/pve/Music" "Musique"'
```

---

## 📝 À améliorer éventuellement

- Envoi de mail avec le rapport
- Retry automatique des erreurs NFS
- Archivage des logs
- Options en ligne de commande pour ne traiter qu'une catégorie

---

> Fichier maintenu par l'utilisateur de Proxmox/OMV pour transferts planifiés.

