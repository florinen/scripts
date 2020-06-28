#!/bin/bash
## This script will backup NC DB and NC instalation folder before any upgrades!!

YELLOW=`tput setaf 3`
GREEN=`tput setaf 2`
MAGENTA=`tput setaf 5`
RESET=`tput sgr0`


CURRDATE=` date '+%m-%d-%Y' `
HOSTNAME="freenas.varu.local"
DB_USER="root"
REMOTE_USER="nc_user"
DB_Name="nextcloud"
NC_FOLDER="/var/www/nextcloud"
DEST_LOCAL="$HOME/nc_backups"
DEST_REMOTE="$HOSTNAME:/mnt/Storage/nfs/Nextcloud/nc_backups/nc_user/backups"
DB_PASS=`ssh  $REMOTE_USER"@"$HOSTNAME "cat /mnt/Storage/nfs/Nextcloud/nc_backups/nc_user/.my*"`

echo "====>$YELLOW Backing up NextCloud database...!! $RESET<===="
mysqldump -u $DB_USER -p$DB_PASS -C $DB_Name > $DEST_LOCAL"/"$DB_Name"_"$CURRDATE.sql.tgz
echo "$GREEN done!! $RESET"
sleep 3
echo "====>$YELLOW Saving $NC_FOLDER folder - as tar file... $RESET<===="
tar -cpvzf $DEST_LOCAL"/"$DB_Name"_"$CURRDATE.tar.gz $NC_FOLDER
echo ""
echo "$GREEN done!! $RESET"
echo ""
echo "Rsync ran today backing up : $DB_Name"_"$CURRDATE.sql  and   $DB_Name"_"$CURRDATE.tar.gz at $(date)" >> $DEST_LOCAL"/"$DB_Name-backup.log 2>&1
echo "=====>$YELLOW Transfer NextCloud backups to remote $RESET<===="
rsync -avzP  $DEST_LOCAL"/" $REMOTE_USER"@"$DEST_REMOTE
echo ""
echo "$GREEN Transfer done!! $RESET"
echo ""
echo "====>$YELLOW Cleanning up $DEST_LOCAL..!! $RESET<===="
rm -fv $DEST_LOCAL"/"$DB_Name*
echo ""
echo "$GREEN done!! $RESET"
echo ""
echo "Rsync ran today backing up :" $DB_Name"_"$CURRDATE.sql " and " $DB_Name"_"$CURRDATE.tar.gz " at  $(date)"
echo "$GREEN Backup COMPLETE!! $RESET"
echo ""

exit

