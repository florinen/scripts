#!/bin/bash 

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
RESET=$(tput sgr0)


CURRDATE=$( date '+%m-%d-%Y' )
NC_FOLDER="nextcloud"
NC_TARGET_VER="19.0.0"
DIR="$HOME/old_nc"
DIR_DNL="$HOME/new_download"
NC_LOCATION="/var/www"
DOWNLOAD_NC="curl -LO https://download.nextcloud.com/server/releases/nextcloud-$NC_TARGET_VER"
NC_OLD_VER=$(sudo -u www-data php /var/www/nextcloud/occ -V |grep -o '[^ ]*$')  # Cut the last field first space being the delimiter


if [[ -d "${DIR_DNL}" ]]; then
  	echo "No need to create ${DIR_DNL}, already exists"
elif [[ ! -e "${DIR_DNL}" ]]; then
   	mkdir "${DIR_DNL}"
fi
## Check the version of NC you want to upgrade to and download it, if not STOP
if [[ "${NC_OLD_VER}" != "${NC_TARGET_VER}" ]]; then
    echo "You are about to upgrade NC to $GREEN >> ${NC_TARGET_VER} <<$RESET...!!!"
    if [[ "${NC_OLD_VER}" != "${NC_TARGET_VER}" ]]; then
        cd "${DIR_DNL}" ;
        ${DOWNLOAD_NC}.zip ;
        unzip "${DIR_DNL}"/"${NC_FOLDER}"-"${NC_TARGET_VER}".zip &>/dev/null ;
        rm "${DIR_DNL}"/"${NC_FOLDER}"-"${NC_TARGET_VER}".zip ; 
        cd ..
    fi
else
    echo "You DON'T need to upgrade, NC version ${YELLOW} >> ${NC_TARGET_VER} is a match with ${NC_OLD_VER} <<$RESET...!!!"
    exit
fi
## Disable NGINX service
NGINX_STATUS=$(/etc/init.d/nginx status |grep Active |awk '{print $2}')
if [[ "${NGINX_STATUS}" = "active" ]]; then
    echo "Stopping Nginx"
    /etc/init.d/nginx stop
elif [[ "${NGINX_STATUS}" = "inactive" ]]; then
    echo "NGINX service not running"
fi
## Remove all cron jobs
CRONJOB=$(crontab  -l -u www-data |cut -d "*" -f1)
if [[ "${CRONJOB}"  = "#" ]]; then
    echo "Cron job is disabled"
  
elif [[ "${CRONJOB}" = "" ]]; then
    echo "Disable the cronjon"
    crontab  -l -u www-data | sed  's/^/#/' |crontab -u www-data -
fi
# Make directory to move old NC folder if exists
if [[ -d "${DIR}" ]]; then
  	echo ""${DIR}" already exists"
elif [[ ! -e "${DIR}" ]]; then
   	mkdir "${DIR}"
fi
## Removing old NC backups if exists
REM_NC_OLD=$(ls -l "${DIR}" |grep -i old |awk '{print $9}')
if [[ "${REM_NC_OLD}" != "" ]]; then  
    echo -e "Removing old backup from ${DIR}/\n${REM_NC_OLD}"
    for val in "${REM_NC_OLD}/*"
    do
       rm -rf "${DIR}"/"${val#*/}"
    done
else 
    echo "Folder not existing, not removed"
fi
## Check if old NC backups exist, move it to new folder create earlier for later deletion, extra step not really need it!!
CHECK_OLD_NC=$(ls -l "${NC_LOCATION}" |grep -i old |awk '{print $9}')
if [[ "${CHECK_OLD_NC}" = "" ]]; then
    echo "Nothing to Move...!!! "
elif [[ "${NC_LOCATION}"/"${NC_FOLDER}"-old ]]; then
    echo "Moving old backup to ${DIR} before deletion..."
    mv "${NC_LOCATION}"/"${NC_FOLDER}"-old* "${DIR}"/    
fi
## Rename current NC folder to nextcloud-old+date
NC_RENAME=$(ls -l "${NC_LOCATION}" |grep -v old |grep  next |grep -o '[^ ]*$')
if [[  "${NC_RENAME}" = "${NC_FOLDER}" ]]; then
    echo "Renameing folder ${NC_FOLDER} to ${NC_FOLDER}-old_"${CURRDATE}""
    mv "${NC_LOCATION}"/"${NC_FOLDER}" "${NC_LOCATION}"/"${NC_FOLDER}"-old_"${CURRDATE}"
else
    echo "NC did not rename"
fi
# Copy new NC to /var/www 
NEW_NC_FOLDER=$(ls -l ${DIR_DNL} |grep nextcloud |awk '{print $9}')
if [[ "${NEW_NC_FOLDER}" != "" ]]; then
    echo "Copy new NC folder to ${NC_LOCATION}/"
    cp -r "${DIR_DNL}"/"${NC_FOLDER}" "${NC_LOCATION}"/ ;
    rm -rf "${DIR_DNL}"/"${NC_FOLDER}"
else
    echo "${NC_FOLDER} did not exist...!!!"
fi
## Copy old config.php to new NC
if [[ -d "${NC_LOCATION}"/"${NC_FOLDER}"-old_"${CURRDATE}" ]]; then
    echo "Copy config.php from old ${NC_LOCATION}/${NC_FOLDER}-old_${CURRDATE} to new ${NC_LOCATION}/${NC_FOLDER}..."
    cp -r "${NC_LOCATION}"/"${NC_FOLDER}"-old_"${CURRDATE}"/config/config.php "${NC_LOCATION}"/"${NC_FOLDER}"/config/config.php
else
    echo "ERROR could not copy config php to "${NC_LOCATION}"/"${NC_FOLDER}"...!!"
fi
# Copy apps folder from old NC to new NC, make sure you delete app folder in new NC before COPYING!!
if [[ -d "${NC_LOCATION}"/"${NC_FOLDER}"/apps ]]; then
    echo "Copying folder APPS from old ${NC_LOCATION}/${NC_FOLDER}-old_${CURRDATE} to new ${NC_LOCATION}/${NC_FOLDER}..."
    rm -rf "${NC_LOCATION}"/"${NC_FOLDER}"/apps ;
    cp -r "${NC_LOCATION}"/"${NC_FOLDER}"-old_"${CURRDATE}"/apps "${NC_LOCATION}"/"${NC_FOLDER}"/
else
    echo "APPS folder did not copy successful"
fi
# Copy this folder only if you have themes ##
if [[ -d "${NC_LOCATION}"/"${NC_FOLDER}"/themes ]]; then
    echo "Copying folder THEMES from old ${NC_LOCATION}/${NC_FOLDER}-old_${CURRDATE} to new ${NC_LOCATION}/${NC_FOLDER}..."
    rm -rf "${NC_LOCATION}"/"${NC_FOLDER}"/themes ;
    cp -r "${NC_LOCATION}"/"${NC_FOLDER}"-old_"${CURRDATE}"/themes "${NC_LOCATION}"/"${NC_FOLDER}"/
else
    echo "Themes folder did not copy successful"
fi
## Adjust file ownership and permissions:
CHECK_OWNER=$(ls -l "${NC_LOCATION}" |grep -v old |grep  next |awk '{print $3" "$4}')
if [[ "${CHECK_OWNER}" != "www-data www-data" ]];then
    echo "Adjusting ${NC_FOLDER} ownership"
    chown -R www-data:www-data /var/www/nextcloud
    chown -R www-data:acmeuser /var/www/letsencrypt
else
    echo "Ownership is correct"
fi
if [[ "${CHECK_OWNER}" != "www-data www-data" ]]; then
    echo "Fix ${NC_FOLDER} files and directory permissions"
    find /var/www/nextcloud/ -type d -exec chmod 750 {} \;
    find /var/www/nextcloud/ -type f -exec chmod 640 {} \;
else
    echo "Error file permission not applied"
fi
## Starting NGINX and Restart Redis and PHP7.3-fpm
NGINX_STATUS=$(/etc/init.d/nginx status |grep Active |awk '{print $2}')
if [[ "${NGINX_STATUS}" = "inactive" ]]; then
    echo "Nginx not running, try starting...!"
    /etc/init.d/nginx restart ;
    /etc/init.d/redis-server restart ;
    /etc/init.d/php7.4-fpm restart
elif [[ "${NGINX_STATUS}" = "active" ]]; then
    echo "NGINX service running"
fi
## Performing the UPGRADE
# echo "Disable app >>files<<"
sudo -u www-data php /var/www/nextcloud/occ app:disable files
echo "Performing the OCC Upgrade..."
sudo -u www-data php /var/www/nextcloud/occ upgrade

## Files do not show up after a upgrade. A rescan of the files can help:
echo "Performing all file scan..."
sudo -u www-data php /var/www/nextcloud/console.php files:scan --all

## When upgrade finished, enable cron-job:
CRONJOB=$(crontab  -l -u www-data |cut -d "*" -f1)
if [[ "${CRONJOB}" = "" ]]; then
    echo "Cron job is enabled"
elif [[ "${CRONJOB}" = "#" ]]; then
    echo "Enable  cronjob"
    crontab  -l -u www-data | sed  's/^.//' |crontab -u www-data -
fi

#######
## Changet NC_TARGET_VER to anything and comment all lines above here to triger manual rollback.
#######
## Rollback ig upgrade fails
## This will check first and see if UPGRADE was successful or not
NC_NEW_VER=$(sudo -u www-data php /var/www/nextcloud/occ -V |grep -o '[^ ]*$')
NC_PREV_VER=$(cat "${NC_LOCATION}"/"${NC_FOLDER}"-old_"${CURRDATE}"/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g" | cut -b -6)

if [[ "${NC_NEW_VER}" = "${NC_TARGET_VER}" ]]; then
    echo "...$GREEN NC successfuly upgraded to version ${NC_NEW_VER}...!!$RESET"
    exit
else 
    echo "${YELLOW}>> Something went wrong, rolling back to old version ${NC_PREV_VER}<<$RESET"
fi
## In case versions not a match then rollback. 
if [[ "${NC_NEW_VER}" != "${NC_TARGET_VER}" ]]; then
    ## Stop NGINX service
    NGINX_STATUS=$(/etc/init.d/nginx status |grep Active |awk '{print $2}')
    if [[ "${NGINX_STATUS}" = "active" ]]; then
        echo "Stopping Nginx"
        /etc/init.d/nginx stop
    elif [[ "${NGINX_STATUS}" = "inactive" ]]; then
        echo "NGINX service not running"
    fi
    ## Remove CronJob
    CRONJOB=$(crontab  -l -u www-data |cut -d "*" -f1)
    if [[ "${CRONJOB}" = "#" ]]; then
        echo "Cron job is disabled"
    elif [[ "${CRONJOB}" = "" ]]; then
        echo "Disable the cronjon"
        crontab  -l -u www-data | sed  's/^/#/' |crontab -u www-data -
    fi
    ## Remove new NC folder and rename backup nextcloud-old+date to nextcloud
    if [[ ! -d "${NC_LOCATION}"/"${NC_FOLDER}"-old_"${CURRDATE}"  ]]; then  
        echo "Folder ${NC_LOCATION}/${NC_FOLDER}-old_${CURRDATE} does not exists..."
    elif [[ -d "${NC_LOCATION}"/"${NC_FOLDER}"-old_"${CURRDATE}" ]]; then
        echo "Renameing folder ${NC_LOCATION}/${NC_FOLDER}-old_${CURRDATE} to ${NC_FOLDER}"
        rm -rf "${NC_LOCATION}"/"${NC_FOLDER}"
        mv "${NC_LOCATION}"/"${NC_FOLDER}"-old_"${CURRDATE}" "${NC_LOCATION}"/"${NC_FOLDER}"  
    fi
    CHECK_OWNER=$(ls -l "${NC_LOCATION}" |grep -v old |grep  next |awk '{print $3" "$4}')
    if [[ "${CHECK_OWNER}" != "www-data www-data" ]];then
        echo "Adjusting ${NC_FOLDER} ownership"
        chown -R www-data:www-data /var/www/nextcloud
        chown -R www-data:acmeuser /var/www/letsencrypt
    else
        echo "Ownership is correct"
    fi
    if [[ "${CHECK_OWNER}" != "www-data www-data" ]]; then
        echo "Fix ${NC_FOLDER} files and directory permissions"
        find /var/www/nextcloud/ -type d -exec chmod 750 {} \;
        find /var/www/nextcloud/ -type f -exec chmod 640 {} \;
    else
        echo "File permission is correct"
    fi

    ## Starting NGINX and Restart Redis and PHP7.3-fpm
    NGINX_STATUS=$(/etc/init.d/nginx status |grep Active |awk '{print $2}')
    if [[ "${NGINX_STATUS}" = "inactive" ]]; then
        echo "Nginx not running, try starting...!"
        /etc/init.d/nginx restart ;
        /etc/init.d/redis-server restart ;
        /etc/init.d/php7.4-fpm restart
    elif [[ "${NGINX_STATUS}" = "active" ]]; then
        echo "NGINX service running"
    fi

## Files do not show up after a upgrade. A rescan of the files can help:
echo "Performing all file scan..."
sudo -u www-data php /var/www/nextcloud/console.php files:scan --all

    CRONJOB=$(crontab  -l -u www-data |cut -d "*" -f1)
    if [[ "${CRONJOB}" = "" ]]; then
        echo "Cron job is enabled"
    elif [[ "${CRONJOB}" = "#" ]]; then
        echo "Enable  cronjob"
        crontab  -l -u www-data | sed  's/^.//' |crontab -u www-data -
    fi
echo "....${YELLOW} Rollback successfully..! $RESET.... "
fi