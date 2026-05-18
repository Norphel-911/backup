#!/bin/bash

# ─── Configuration locale ─────────────────────────────────────
SITE_SRC="/var/www/html/site"
JEU_SRC="/var/www/html/serveur_jeu"
BACKUP_DIR="/backup"
GARDER=7                        # nombre de backups à conserver
DATE=$(date +"%Y-%m-%d_%H-%M")
# ─────────────────────────────────────────────────────────────

# ─── Configuration distante ───────────────────────────────────
DISTANT_USER="tenzin"           # utilisateur SSH sur la VM distante
DISTANT_IP="192.168.6.4"        # IP de ta VM DNS/Oxidized
DISTANT_DIR="/backup/distant"   # dossier de destination sur la VM distante
# ─────────────────────────────────────────────────────────────

# Créer le dossier backup local s'il n'existe pas
mkdir -p "$BACKUP_DIR"

echo "================================================"
echo " Backup démarré : $DATE"
echo "================================================"

# ─── Sauvegarde du site ───────────────────────────────────────
echo ""
echo "[1/2] Sauvegarde du site..."
tar -czf "$BACKUP_DIR/site_$DATE.tar.gz" -C "$(dirname $SITE_SRC)" "$(basename $SITE_SRC)"
echo "      ✓ site_$DATE.tar.gz créé"

# ─── Sauvegarde du serveur jeu ────────────────────────────────
echo ""
echo "[2/2] Sauvegarde du serveur jeu..."
tar -czf "$BACKUP_DIR/serveur_jeu_$DATE.tar.gz" -C "$(dirname $JEU_SRC)" "$(basename $JEU_SRC)"
echo "      ✓ serveur_jeu_$DATE.tar.gz créé"

# ─── Rotation des anciens backups ─────────────────────────────
echo ""
echo "--- Rotation des anciens backups (conservation : $GARDER derniers) ---"

for service in "site" "serveur_jeu"; do
    anciens=$(ls -t "$BACKUP_DIR/${service}_"*.tar.gz 2>/dev/null | tail -n +$((GARDER + 1)))
    if [ -n "$anciens" ]; then
        echo "$anciens" | xargs rm
        echo "      ✓ Anciens backups $service supprimés"
    else
        echo "      ✓ Rien à supprimer pour $service"
    fi
done

# ─── Envoi vers serveur distant ───────────────────────────────
echo ""
echo "--- Envoi vers serveur distant ($DISTANT_IP) ---"
rsync -avz "$BACKUP_DIR/" "$DISTANT_USER@$DISTANT_IP:$DISTANT_DIR/"

if [ $? -eq 0 ]; then
    echo "      ✓ Backup distant terminé"
else
    echo "      ✗ Erreur lors du transfert distant"
fi

# ─── Résumé final ─────────────────────────────────────────────
echo ""
echo "================================================"
echo " Backup terminé"
echo " Fichiers dans $BACKUP_DIR :"
ls -lh "$BACKUP_DIR"
echo "================================================"

#sssh passphrase=ssh.key
