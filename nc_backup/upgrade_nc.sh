#!/bin/bash 

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
RESET=$(tput sgr0)


CURRDATE=$( date '+%m-%d-%Y' )
APP_NAME="nextcloud"
NC_TARGET_VER="23.0.5"
DIR="$HOME/old_nc"
DIR_DNL="$HOME/new_download"
NC_LOCATION="/var/www"
DOWNLOAD_NC="curl -LO https://download.nextcloud.com/server/releases/nextcloud-$NC_TARGET_VER"
PHP_VER="7.4"
DOWNLOAD=$(curl -s 'https://download.nextcloud.com/server/releases/' |awk -F'nextcloud-' '{print $2}' |sed 's/["\>]//g' |grep -E '\.zip$' |grep $NC_TARGET_VER)  
## FUNCTIONS ##

STATUS () {
    echo "$?"
}

## Check NC versions
version_check(){
    #NC_OLD_VER=$(sudo -u www-data php ${NC_LOCATION}/${APP_NAME}/occ -V |grep -o '[^ ]*$')  # Cut the last field first space being the delimiter
    NC_OLD_VER=$(sudo -u www-data php ${NC_LOCATION}/${APP_NAME}/occ -V |awk '{print $NF}')
    NC_NEW_VER=$(sudo -u www-data php ${NC_LOCATION}/${APP_NAME}/occ -V |awk '{print $NF}')
    OLD_CONF=$(ls -l "${NC_LOCATION}" |grep -i old |awk '{print $9}')
    NC_CURRENT_VER=$(sudo -u www-data php ${NC_LOCATION}/${APP_NAME}/occ -V |awk '{print $NF}'| cut -d'.' -f1)
    TARGET_VER=$(echo "${NC_TARGET_VER}" | cut -d'.' -f1)
    
    if [[ ${OLD_CONF} = "" ]]; then
        echo "$YELLOW>>Previous config.php not available right now!!!<<$RESET"
    else
        #NC_PREV_VER=$(cat "${NC_LOCATION}"/"${APP_NAME}"-old_"${CURRDATE}"/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g" | cut -b -6)
        NC_PREV_VER=$(sudo -u www-data php  ${NC_LOCATION}/${APP_NAME}-old_${CURRDATE}/occ -V |awk '{print $NF}')
    fi
}

## Make directories 
create_dir(){
    if [[ -d "${DIR_DNL}" ]]; then
        echo "No need to create ${DIR_DNL}, already exists" 1>/dev/null
    else 
        echo "Creating download directory!"
        mkdir "${DIR_DNL}"
    fi
    if [[ -d "${DIR}" ]]; then
        echo "No need to create ${DIR}, already exists" 1>/dev/null
    else 
        echo "Creating backup directory!"
        mkdir "${DIR}"
    fi
if [[ "$(STATUS)" -ne 0 ]]; then 
    echo "Make Dir command did not execute successlully "
    exit 1
fi
}
## Stop and Start services
service_check(){
    NGINX_STATUS=$(/etc/init.d/nginx status |grep Active |awk '{print $2}')
    if [[ "${NGINX_STATUS}" = "inactive" ]]; then
        echo "Restarting Nginx, Redis and PHP...!"
        /etc/init.d/nginx restart 
        /etc/init.d/redis-server restart
        /etc/init.d/php"${PHP_VER}"-fpm restart
    elif [[ "${NGINX_STATUS}" = "active" ]]; then
        echo "NGINX service running, stopping it now...!"
        /etc/init.d/nginx stop
    fi
if [[ "$(STATUS)" -ne 0 ]]; then 
    echo "Nginx service check command did not execute successlully "
fi
}

## Disable and enable CronJobs
check_cronjob(){
    CRONJOB=$(crontab  -l -u www-data |grep -w php |grep "#")
    if [[ -z "${CRONJOB}"  ]]; then
        echo "Cron job is enabled, disabling now...!"
        crontab  -l -u www-data | sed  's/^/#/' |crontab -u www-data -
        
        if [[ "$(STATUS)" -eq 0 ]]; then
            echo "${GREEN}Successfully disabled...${RESET}"
        else
            echo "${RED}Ooops!!!${RESET} Unexpected error disabling Cron job..."
        fi
    elif [[ -n "${CRONJOB}" ]]; then
        echo "Cron job is disabled, enabling now...!"
        crontab  -l -u www-data | sed  's/^.//' |crontab -u www-data -
    
        if [[ "$(STATUS)" -eq 0 ]]; then
            echo "${GREEN}Successfully enabled...${RESET} "
        else
            echo "${RED}Ooops!!!${RESET} Unexpected error enabling Cron job..."
        fi
    fi
}
## Check Ownership and Permissions of NC files and folders
ckeck_owner_permissions(){
    CHECK_OWNER=$(ls -l "${NC_LOCATION}" |grep -v old |grep  next |awk '{print $3" "$4}')
    if [[ "${CHECK_OWNER}" != "www-data www-data" ]];then
        echo "Adjusting ${APP_NAME} ownership"
        chown -R www-data:www-data ${NC_LOCATION}/${APP_NAME}
        chown -R www-data:acmeuser /var/www/letsencrypt
    else
        echo "Ownership is correct!"
    fi
    if [[ "${CHECK_OWNER}" != "www-data www-data" ]]; then
        echo "Fix ${APP_NAME} files and directory permissions"
        find ${NC_LOCATION}/${APP_NAME}/ -type d -exec chmod 750 {} \;
        find ${NC_LOCATION}/${APP_NAME}/ -type f -exec chmod 640 {} \;   #May have permission issues  
    else                                                            
        echo "File permission is correct!"
    fi
if [[ "$(STATUS)" -ne 0 ]]; then 
    echo "Error check command did not execute successlully "
fi
}
## Performing file scan
file_scan(){
    sudo -u www-data php ${NC_LOCATION}/${APP_NAME}/console.php files:scan --all

    if [[ "$(STATUS)" -ne 0 ]]; then 
        echo "Error scan command did not execute successlully "
    fi
}
## Fixing missing indices:
missing_indices() {
    if [[ "$(STATUS)" -eq 0 ]]; then
        echo ""
        echo "Fixing DB missing opjects"
        sleep 3
        bash $(find $HOME -name db_missing_objects.sh) 
    else 
        STATUS
    fi
}
## Performing the Upgrade
nc_upgrade(){
sudo -u www-data php ${NC_LOCATION}/${APP_NAME}/occ upgrade

    if [[ "$(STATUS)" -ne 0 ]]; then 
        echo "Error upgrade command did not execute successlully "
    fi
}

## Check if folder NC new or old exist
folder_check(){
    REM_NC_OLD=$(ls -l "${DIR}" |grep -i old |awk '{print $9}')
    CHECK_OLD_NC=$(ls -l "${NC_LOCATION}" |grep -i old |awk '{print $9}')
    NC_RENAME=$(ls -l "${NC_LOCATION}" |grep -v old |grep  next |grep -o '[^ ]*$')
    NEW_NC_FOLDER=$(ls -l "${DIR_DNL}" |grep nextcloud |awk '{print $9}')
}

##+++++++++++++++++++++++#
## STARTING the UPGRADE ##
##+++++++++++++++++++++++#
 
version_check
value=$(($TARGET_VER - $NC_CURRENT_VER ))
if [[ "${value}" -eq "0" ]]; then
    echo "${GREEN}Upgrading NC with $0 ${RESET}"
else 
    echo -e "Please update via Web UI or continue with executing: ${YELLOW}sudo -u www-data php ${NC_LOCATION}/${APP_NAME}/updater/updater.phar --no-interaction${RESET} \n"
    echo "${YELLOW}ONLY ${RESET}Y\y ${YELLOW}will proceed forward with upgrade, press anything else will cancel.!!${RESET}"
    read -p "${YELLOW}Would you like to continue with update: ${RESET}" ANSWER
    if [[ $ANSWER == [Yy]* ]]; then
        echo "Proceeding with Applying Upgrade"
        sudo -u www-data php ${NC_LOCATION}/${APP_NAME}/updater/updater.phar --no-interaction     
    else
        echo "${RED}Applying Changes Canceled!!${RESET}"
        exit 1
    fi
    missing_indices
    version_check
    echo "...$GREEN NC successfuly upgraded to version ${NC_NEW_VER}...!!$RESET"
    exit 
fi

# Create download directory
create_dir
## Check the version of NC you want to upgrade to and download it, if not STOP
version_check
if [[ "${NC_OLD_VER}" != "${NC_TARGET_VER}" ]]; then
    echo "You are about to upgrade NC to $GREEN >> ${NC_TARGET_VER} <<$RESET...!!!"
    if [[ "${NC_OLD_VER}" != "${NC_TARGET_VER}" ]]; then
        create_dir ; cd "${DIR_DNL}" ;
        ${DOWNLOAD_NC}.zip ;
        unzip "${DIR_DNL}"/"${APP_NAME}"-"${NC_TARGET_VER}".zip &>/dev/null ;
        rm "${DIR_DNL}"/"${APP_NAME}"-"${NC_TARGET_VER}".zip ; 
        cd ..
    fi
else
    echo "You DON'T need to upgrade, NC version ${YELLOW} >> ${NC_TARGET_VER} is a match with ${NC_OLD_VER} <<$RESET...!!!"
    exit
fi

## Check NGINX service and disable it
service_check
## Check and remove all cron jobs
check_cronjob

## Make directory to move old NC folder if exists
## Removing old NC backups if exists
folder_check
if [[ -z "${REM_NC_OLD}" ]]; then  
    echo "Folder does not exists!!"
else
    echo -e "Removing old backup from ${DIR}/\n${REM_NC_OLD}"
    rm -rf "${DIR}"/*
fi
## Check if old NC backups exist, move it to new folder created earlier for later deletion, extra step not really need it!!
folder_check
if [[ -z "${CHECK_OLD_NC}" ]]; then
    echo "Nothing to Move...!!! "
else
    echo "Moving old backup to ${DIR} before deletion..."
    mv "${NC_LOCATION}"/"${APP_NAME}"-old* "${DIR}"/    
fi
## Rename current NC folder to nextcloud-old+date
folder_check
if [[ -z "${NC_RENAME}" ]]; then
        echo "NC did not rename"
else
    echo "Renameing folder ${APP_NAME} to ${APP_NAME}-old_"${CURRDATE}""
    mv "${NC_LOCATION}"/"${APP_NAME}" "${NC_LOCATION}"/"${APP_NAME}"-old_"${CURRDATE}"
fi
# # Copy new just downloaded NC to /var/www 
folder_check
if [[ -z "${NEW_NC_FOLDER}" ]]; then
    echo "New downloaded ${APP_NAME} did not exist...!!!"
else
    echo "Copy new NC folder to ${NC_LOCATION}/"
    cp -r "${DIR_DNL}"/"${APP_NAME}" "${NC_LOCATION}"/ ;
    rm -rf "${DIR_DNL}"/"${APP_NAME}"
fi
# ## Copy old config.php fron old NC folder to new NC
if [[ -d "${NC_LOCATION}"/"${APP_NAME}"-old_"${CURRDATE}" ]]; then
    echo "Copy config.php from old ${NC_LOCATION}/${APP_NAME}-old_${CURRDATE} to new ${NC_LOCATION}/${APP_NAME}..."
    cp -r "${NC_LOCATION}"/"${APP_NAME}"-old_"${CURRDATE}"/config/config.php "${NC_LOCATION}"/"${APP_NAME}"/config/config.php
else
    echo "ERROR could not copy config php to "${NC_LOCATION}"/"${APP_NAME}"...!!"
fi
# Copy apps folder from old NC to new NC, make sure you delete app folder in new NC before COPYING!!
if [[ -d "${NC_LOCATION}"/"${APP_NAME}"/apps ]]; then
    echo "Copying folder APPS from old ${NC_LOCATION}/${APP_NAME}-old_${CURRDATE} to new ${NC_LOCATION}/${APP_NAME}..."
    rm -rf "${NC_LOCATION}"/"${APP_NAME}"/apps ;
    cp -r "${NC_LOCATION}"/"${APP_NAME}"-old_"${CURRDATE}"/apps "${NC_LOCATION}"/"${APP_NAME}"/
else
    echo "APPS folder did not copy successful"
fi
# Copy this folder only if you have themes ##
if [[ -d "${NC_LOCATION}"/"${APP_NAME}"/themes ]]; then
    echo "Copying folder THEMES from old ${NC_LOCATION}/${APP_NAME}-old_${CURRDATE} to new ${NC_LOCATION}/${APP_NAME}..."
    rm -rf "${NC_LOCATION}"/"${APP_NAME}"/themes ;
    cp -r "${NC_LOCATION}"/"${APP_NAME}"-old_"${CURRDATE}"/themes "${NC_LOCATION}"/"${APP_NAME}"/
else
    echo "Themes folder did not copy successful"
fi
## Adjust file ownership and permissions:
ckeck_owner_permissions
## Starting NGINX and Restart Redis and PHP7.3-fpm
service_check

## Performing the UPGRADE of NC
# echo "Disable app >>files<<"
#sudo -u www-data php ${NC_LOCATION}/${APP_NAME}/occ app:disable files
echo "Performing the OCC Upgrade..."

version_check
## Upgrading
nc_upgrade

## Files do not show up after a upgrade. A rescan of the files can help:
echo "Performing all file scan..."
file_scan
## When upgrade finished, enable cron-job:
check_cronjob

# Fixing missing index:
missing_indices

#++++++++++++++++++++++++++++++##
# Rolling back if upgrade fails##
#++++++++++++++++++++++++++++++##

## Changet NC_TARGET_VER to anything and comment all lines above here to triger manual rollback.
## This will check first and see if UPGRADE was successful or not

version_check
if [[ "${NC_NEW_VER}" = "${NC_TARGET_VER}" ]]; then
    echo "...$GREEN NC successfuly upgraded to version ${NC_NEW_VER}...!!$RESET"
    exit
else 
    echo "${YELLOW}>> Something went wrong, rolling back to previous version ${NC_PREV_VER}<<$RESET"
fi
## In case versions not a match then rollback. 
if [[ "${NC_NEW_VER}" != "${NC_TARGET_VER}" ]]; then
    ## Stop NGINX service
     service_check
    ## Remove CronJob
     check_cronjob
    ## Remove new NC folder and rename backup nextcloud-old+date to nextcloud
    if [[ ! -d "${NC_LOCATION}"/"${APP_NAME}"-old_"${CURRDATE}"  ]]; then  
        echo "Folder ${NC_LOCATION}/${APP_NAME}-old_${CURRDATE} does not exists..."
    elif [[ -d "${NC_LOCATION}"/"${APP_NAME}"-old_"${CURRDATE}" ]]; then
        echo "Renameing folder ${NC_LOCATION}/${APP_NAME}-old_${CURRDATE} to ${APP_NAME}"
        rm -rf "${NC_LOCATION}"/"${APP_NAME}"
        mv "${NC_LOCATION}"/"${APP_NAME}"-old_"${CURRDATE}" "${NC_LOCATION}"/"${APP_NAME}"  
    fi
    ## Apply correct owner and permission
    ckeck_owner_permissions
    ## Starting NGINX and Restart Redis and PHP7.3-fpm
       service_check
    ## Files do not show up after a upgrade. A rescan of the files can help:
    echo "Performing all file scan..."
    file_scan

    ## Enable Cron
    check_cronjob
    echo "....${YELLOW} Rollback successfully..! $RESET.... "
fi
