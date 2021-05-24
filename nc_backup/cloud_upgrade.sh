#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
RESET=$(tput sgr0)

STATUS () {
    echo "$?"
}

echo "Date is: ${GREEN}`date`${RESET}"
echo "You are login as: ${GREEN}`whoami`${RESET}"
echo ""

# Executing DB backup script
echo -e "${GREEN}Before update NC will backup DB first... \nBacking up DB...${RESET}"
/bin/bash $(locate -i backup_cloud.sh) &> >(grep -E 'done!!|COMPLETE!!')

if [[ "$(STATUS)" != "0" ]]; then
    echo "${RED}Backing up NC DB failed.!!${RESET}"
fi
sleep 2

# Executinh Upgrade NC script
echo -e "${GREEN}Upgrading NC starts now... \nUpgrading...${RESET}"
/bin/bash $(locate -i upgrade_nc.sh)

if [[ "$(STATUS)" != "0" ]]; then
    echo "${RED}Upgrading NC failed.!!${RESET}"
fi

