#!/bin/bash -e

YELLOW=`tput setaf 3`
GREEN=`tput setaf 2`
MAGENTA=`tput setaf 5`
RESET=`tput sgr0`


CURRDATE=` date '+%m-%d-%Y' `
NC_FOLDER="nextcloud"
NC_VERSION="18.0.6"
DIR="$HOME/old_nc"
NC_LOCATION="/var/www"



curl -LO https://download.nextcloud.com/server/releases/nextcloud-$NC_VERSION.zip ;unzip nextcloud-$NC_VERSION.zip &>/dev/null; rm nextcloud-$NC_VERSION.zip

NGINX_STATUS=`/etc/init.d/nginx status |grep Active |awk '{print $2}'`
if [[ $NGINX_STATUS == "active" ]]; then
    echo "Stopping Nginx"
    /etc/init.d/nginx stop
elif [[ $NGINX_STATUS == "inactive" ]]; then
    echo "NGINX service not running"
fi

if [[  $(crontab  -l -u www-data |cut -d "*" -f1) = "#" ]]; then
    echo "Cron job is disabled"
  
elif [[ $(crontab  -l -u www-data |cut -d "*" -f1) = "" ]]; then
    echo "Disable the cronjon"
    crontab  -l -u www-data | sed  's/^/#/' |crontab -u www-data -
fi

if [[ -d $DIR ]]; then
  	echo "$DIR already exists"
elif [[ ! -e $DIR ]]; then
   	mkdir $DIR
fi
	
if [[ $DIR/$NC_FOLDER-old  ]]; then  
    echo "Removing $DIR/$NC_FOLDER-old..."
    rm -rf $DIR/$NC_FOLDER-old
else 
    echo "Folder did not get removed"
fi

if [[ $(ls -l $NC_LOCATION |grep -i old |awk '{print $9}') == "" ]]; then
    echo "Nothing to Move!!! "
elif [[ $NC_LOCATION/$NC_FOLDER-old ]]; then
    echo "Moving old backup to $DIR before deletion..."
    mv $NC_LOCATION/$NC_FOLDER-old* $DIR/    
fi

if [[ ! -d $NC_LOCATION/$NC_FOLDER-old ]]; then
    echo "Renameing folder $NC_FOLDER to $NC_FOLDER-old_$CURRDATE"
    mv $NC_LOCATION/$NC_FOLDER $NC_LOCATION/$NC_FOLDER-old_$CURRDATE
else
    echo "did not rename"
fi
if [[ ! -d $NC_LOCATION/$NC_FOLDER ]]; then
    echo "Copy new NC folder to $NC_LOCATION/"
    cp -r $HOME/$NC_FOLDER $NC_LOCATION/ ;
    rm -r $HOME/$NC_FOLDER
else
    echo "$NC_FOLDER did not copy"
fi

if [[ -d $NC_LOCATION/$NC_FOLDER-old_$CURRDATE ]]; then
    echo "Copy config.php from old $NC_LOCATION/$NC_FOLDER-old_$CURRDATE to new $NC_LOCATION/$NC_FOLDER..."
    cp -r $NC_LOCATION/$NC_FOLDER-old_$CURRDATE/config/config.php $NC_LOCATION/$NC_FOLDER/config/config.php
else
    echo "ERROR could not copy config php to $NC_LOCATION/$NC_FOLDER...!!"
fi
if [[ -d $NC_LOCATION/$NC_FOLDER/apps ]]; then
    echo "Copying folder APPS from old $NC_LOCATION/$NC_FOLDER-old_$CURRDATE to new $NC_LOCATION/$NC_FOLDER..."
    rm -rf $NC_LOCATION/$NC_FOLDER/apps ;
    cp -r $NC_LOCATION/$NC_FOLDER-old_$CURRDATE/apps $NC_LOCATION/$NC_FOLDER/
else
    echo "APPS folder did not copy successful"
fi
### Copy this folder only if you have themes ##
if [[ -d $NC_LOCATION/$NC_FOLDER/themes ]]; then
    echo "Copying folder THEMES from old $NC_LOCATION/$NC_FOLDER-old_$CURRDATE to new $NC_LOCATION/$NC_FOLDER..."
    rm -rf $NC_LOCATION/$NC_FOLDER/themes ;
    cp -r $NC_LOCATION/$NC_FOLDER-old_$CURRDATE/themes $NC_LOCATION/$NC_FOLDER/
else
    echo "THEMES folder did not copy successful"
fi
#Adjust file ownership and permissions:

if [[  $(ls -l $NC_LOCATION |grep  -vE 'old|lets' |awk '{print $3" "$4}') != "www-data www-data" ]];then
    echo "Adjusting $NC_FOLDER ownership"
    chown -R www-data:www-data /var/www/nextcloud
    #chown -R www-data:acmeuser /var/www/letsencrypt
else
    echo "Ownership is correct"
fi
if [[ $(ls -l $NC_LOCATION |grep  -vE 'old|lets' |awk '{print $3" "$4}') != "www-data www-data" ]]; then
    echo "Fix $NC_FOLDER files and directory permissions"
    find /var/www/nextcloud/ -type d -exec chmod 750 {} \;
    find /var/www/nextcloud/ -type f -exec chmod 640 {} \;
else
    echo "Error file permission not applied"
fi

## Starting NGINX
NGINX_STATUS=`/etc/init.d/nginx status |grep Active |awk '{print $2}'`
if [[ $NGINX_STATUS == "inactive" ]]; then
    echo "Nginx not running, try starting...!"
    /etc/init.d/nginx restart
elif [[ $NGINX_STATUS == "active" ]]; then
    echo "NGINX service running"
fi
## Performing the UPGRADE
#from outside nextcloud directory:
echo "Performing the OCC Upgrade..."
sudo -u www-data php /var/www/nextcloud/occ upgrade
#files do not show up after a upgrade. A rescan of the files can help:
echo "Performing all file scan..."
sudo -u www-data php /var/www/nextcloud/console.php files:scan --all

# #When upgrade finished, Reenable the nextcloud cron-job:
if [[  $(crontab  -l -u www-data |cut -d "*" -f1) = "" ]]; then
    echo "Cron job is enabled"
  
elif [[ $(crontab  -l -u www-data |cut -d "*" -f1) = "#" ]]; then
    echo "Enable  cronjob"
    crontab  -l -u www-data | sed  's/^.//' |crontab -u www-data -
fi


new_ver=$(cat /var/www/nextcloud/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g" | cut -b -6)

if [[ $(cat /var/www/nextcloud/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g" | cut -b -6) == $NC_VERSION ]]; then
    new_ver=$(cat /var/www/nextcloud/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g" | cut -b -6)
    echo "....$GREEN NC successfuly upgraded new version is $new_ver $RESET...."
    exit
elif [[ $(cat /var/www/nextcloud/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g" | cut -b -6) != $NC_VERSION ]]; then
    old_ver=$(cat /var/www/nextcloud/config/config.php | grep version | awk '{print $3}' | sed "s/['\,,\"]//g" | cut -b -6)
    echo "Something went wrong, rolling back to old version $old_ver"
fi
NGINX_STATUS=`/etc/init.d/nginx status |grep Active |awk '{print $2}'`
if [[ $NGINX_STATUS == "active" ]]; then
    echo "Stopping Nginx"
    /etc/init.d/nginx stop
elif [[ $NGINX_STATUS == "inactive" ]]; then
    echo "NGINX service not running"
fi
if [[  $(crontab  -l -u www-data |cut -d "*" -f1) = "#" ]]; then
    echo "Cron job is disabled"
elif [[ $(crontab  -l -u www-data |cut -d "*" -f1) = "" ]]; then
    echo "Disable the cronjon"
    crontab  -l -u www-data | sed  's/^/#/' |crontab -u www-data -
fi

if [[ ! -d $NC_LOCATION/$NC_FOLDER-old_$CURRDATE  ]]; then  
    echo "Folder $NC_LOCATION/$NC_FOLDER-old_$CURRDATE does not exists..."
elif [[ -d $NC_LOCATION/$NC_FOLDER-old_$CURRDATE ]]; then
    echo "Renameing folder $NC_LOCATION/$NC_FOLDER-old_$CURRDATE to $NC_FOLDER"
    rm -rf $NC_LOCATION/$NC_FOLDER
    mv $NC_LOCATION/$NC_FOLDER-old_$CURRDATE $NC_LOCATION/$NC_FOLDER  
fi

NGINX_STATUS=`/etc/init.d/nginx status |grep Active |awk '{print $2}'`
if [[ $NGINX_STATUS == "inactive" ]]; then
    echo "Nginx not running, try starting...!"
    /etc/init.d/nginx restart
elif [[ $NGINX_STATUS == "active" ]]; then
    echo "NGINX service running"
fi
if [[  $(crontab  -l -u www-data |cut -d "*" -f1) = "" ]]; then
    echo "Cron job is enabled"
  
elif [[ $(crontab  -l -u www-data |cut -d "*" -f1) = "#" ]]; then
    echo "Enable  cronjob"
    crontab  -l -u www-data | sed  's/^.//' |crontab -u www-data -
fi
echo "....$YELLOW Rollback successfully..! $RESET.... "
