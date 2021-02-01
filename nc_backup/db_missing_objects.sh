#!/bin/bash

##Some DB missing opjects. After testing add all extra CMD's here:
## Executed by upgrade_nc.sh
BD_OBJECTS=$(add-missing-indices add-missing-columns add-missing-primary-keys convert-filecache-bigint)
sudo -u www-data php /var/www/nextcloud/occ db:add-missing-indices
sudo -u www-data php /var/www/nextcloud/occ db:add-missing-columns
sudo -u www-data php /var/www/nextcloud/occ db:add-missing-primary-keys
sudo -u www-data php /var/www/nextcloud/occ db:convert-filecache-bigint << EOF
y
EOF
echo ""

