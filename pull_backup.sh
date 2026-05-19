#!/bin/bash 

SOURCE_IP="192.168.6.2"
SOURCE_USER="g1admin" 
SOURCE_DIR="/var/www/html"

BACKUP_DIR="/backup/distant"
DATE=$(date +"%Y-%m-%d_%H-%M")
GARDER=7
LOG="/var/log/pull_backup.log"
SSH_KEY="/home/..."

sudo mkdir -p "$BACKUP_DIR"

echo "================================================" >> "$LOG"
echo " Pull backup démarré : $DATE"                     >> "$LOG"
echo "================================================" >> "$LOG" 

if ! ping -c 2 -W 3 "$SOURCE_IP" &>/dev/null; then 
	echo "[$DATE] - Source $SOURCE_IP inaccessible, abandon." >> "$LOG"
	exit 1         # quitte le script avec un code d'erreur
fi 

echo "[$DATE] - Source joinable" >> "$LOG"

#-----Pull rsync------

echo "[$DATE] Début du pull depuis $SOURCE_IP.." >> "$LOG"

sudo rsync -avc \ 
	-e "ssh -i $SSH_KEY" \
	"$SOURCE_USER@$SOURCE_IP:$SOURCE_DIR" \
	"$BACKUP_DIR/$DATE/" >> "$LOG" 2>&1

if [ $? -eq 0 ]; then      # si le code retour de rsync == 0 (succès)
	echo "[$DATE] Pull terminé avec succès" >> "$LOG"
else 
	echo "[$DATE] Erreur rsync" >> "$LOG"
fi

#----Rotation des anciens backups-----

echo "[$DATE] Rotation : conservation des $GARDER derniers..." >> "$LOG"

ls -dt "$BACKUP_DIR"/*/ 2>/dev/null | tail -n +$((GARDER + 1)) | sudo xargs rm -rf 

echo "[$DATE] Rotation terminée" >> "$LOG"
echo "=====================" >> "$LOG"


