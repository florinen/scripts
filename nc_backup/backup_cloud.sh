#!/bin/bash
## This script will backup NC DB and NC instalation folder before any upgrades!!

YELLOW=`tput setaf 3`
GREEN=`tput setaf 2`
MAGENTA=`tput setaf 5`
RESET=`tput sgr0`


CURRDATE=` date '+%m-%d-%Y' `
REMOTE_HOST="freenas.varu.local"
REMOTE_USER="nc_user"

# Can get the DB name from mysql:
#DB_NAME=$(mysql -u ${DB_USER} -p${DB_PASS} -e 'show databases;' |grep dDB)
## Backing up for a speciffic user: 
#DB_USER=$(cat /var/www/nextcloud/config/config.php |grep dbuser |cut -d'>' -f2 |sed "s/[ '\,]//g")

# If you dont know the current DB credentials:
DB_NAME=$(cat /var/www/nextcloud/config/config.php |grep dbname |cut -d'>' -f2 |sed "s/[ '\,]//g")
## Backing up all DB's available in mysql using root USER: 
DB_USER="root"
DB_PASS=$(cat /var/www/nextcloud/config/config.php |grep dbpassword |cut -d'>' -f2 |sed "s/[ '\,]//g")

NC_VERSION=$(sudo -u www-data php /var/www/nextcloud/occ -V |awk '{print $NF}')
NC_FOLDER="/var/www/nextcloud"
DEST_LOCAL="${HOME}/nc_backups"
DEST_REMOTE="${REMOTE_HOST}:/mnt/Storage/nfs/Nextcloud/nc_backups/nc_user/backups"
#DB_PASS=`ssh  ${REMOTE_USER}"@"${REMOTE_HOST} "cat /mnt/Storage/nfs/Nextcloud/nc_backups/nc_user/.my*"`

if [ -d  ${NC_FOLDER} ]; then
            
    # test if database folder exists
    if [ ! -d ${DEST_LOCAL} ]; then
        echo "Backup folder doesn't exists on your filesystem."
        mkdir -p ${HOME}/nc_backups
        if [ -d ${HOME}/nc_backups ]; then
            echo "Folder ${DEST_LOCAL} was created.."
        else 
            echo "Backup folder could not be created - ERROR!"
        fi
    fi 
fi     
echo "====>${YELLOW} Backing up NextCloud database...!! ${RESET}<===="
mysqldump -u ${DB_USER} -p${DB_PASS} -C ${DB_NAME} &>/dev/null > ${DEST_LOCAL}"/"${HOSTNAME}"_"${DB_NAME}"_"${CURRDATE}"_v"${NC_VERSION}.sql.tgz

if [[ "${?}" -ne 0 ]]; then
    echo "Backing up DB ${DB_NAME} was not successful.!!"
    exit "${?}"
else
    echo "${DB_NAME} backup: ${GREEN} done!! ${RESET}"
fi

sleep 3
echo "====>${YELLOW} Saving ${NC_FOLDER} folder - as tar file... ${RESET}<===="
tar -cpvzf ${DEST_LOCAL}"/"${HOSTNAME}"_"${DB_NAME}"_"${CURRDATE}"_v"${NC_VERSION}.tar.gz ${NC_FOLDER}
echo ""
if [[ "${?}" -ne 0 ]]; then
    echo "Archiving DB ${DB_NAME} was not successful.!!"
    exit "${?}"
else
    echo "${DB_NAME} archiving: ${GREEN} done!! ${RESET}"
fi

echo ""
echo "Rsync ran today backing up : ${HOSTNAME}"_"${DB_NAME}"_"${CURRDATE}"_v"${NC_VERSION}.sql  and   ${HOSTNAME}"_"${DB_NAME}"_"${CURRDATE}"_v"${NC_VERSION}.tar.gz at $(date)" >> ${DEST_LOCAL}"/"${HOSTNAME}"_"${DB_NAME}-backup.log 2>&1
echo "=====>${YELLOW} Transfer NextCloud backups to remote ${RESET}<===="
rsync -avzP  ${DEST_LOCAL}"/" ${REMOTE_USER}"@"${DEST_REMOTE}
echo ""
if [[ "${?}" -ne 0 ]]; then
    echo "Rsync DB ${DB_NAME} was not successful.!!"
    exit "${?}"
else
    echo "${DB_NAME} rsync: ${GREEN} done!! ${RESET}"
fi
echo ""
echo "====>${YELLOW} Cleanning up ${DEST_LOCAL}..!! ${RESET}<===="
rm -fv ${DEST_LOCAL}"/"${HOSTNAME}*
echo ""
if [[ "${?}" -ne 0 ]]; then
    echo "Cleanning up was not successful.!!"
    exit "${?}"
else
    echo "Clean up: ${GREEN} done!! ${RESET}"
fi
echo ""
echo "Rsync ran today backing up :" ${HOSTNAME}"_"${DB_NAME}"_"${CURRDATE}"_v"${NC_VERSION}.sql " and " ${HOSTNAME}"_"${DB_NAME}"_"${CURRDATE}"_v"${NC_VERSION}.tar.gz " at  $(date)"
echo "${GREEN}Backup COMPLETE!! ${RESET}"
exit

