#!/bin/bash

APP_NAME="nextcloud"
NC_LOCATION="/var/www"

##Some DB missing opjects. After testing add all extra CMD's here:
## Executed by upgrade_nc.sh
## Add all missing objects below:
BD_OBJECTS="add-missing-indices add-missing-columns add-missing-primary-keys convert-filecache-bigint"
echo ""

# Fixing DB errors after upgrade.
for object in $(echo "${BD_OBJECTS}" |xargs -n1 )
do
    sudo -u www-data php ${NC_LOCATION}/${APP_NAME}/occ db:"${object}" << EOF
y
Y
EOF
done