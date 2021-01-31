#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
RESET=$(tput sgr0)

echo "Date is: ${GREEN}`date`${RESET}"
echo "You are login as: ${GREEN}`whoami`${RESET}"
echo ""
echo "${GREEN}Before update NC will backup DB first...${RESET}"

/bin/bash $HOME/scripts/nc_backup/backup_cloud.sh &> >(grep -E "done!!|COMPLETE!!") 
sleep 2
echo ""
echo "${GREEN}Upgrading NC starts now...${RESET}"

/bin/bash $HOME/scripts/nc_backup/upgrade_nc.sh