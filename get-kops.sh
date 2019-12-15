#!/bin/bash

# Author <sadykovfarkhod@gmail.com>
# Modifier <nenf@yahoo.com>
# Script to download Kops and set up for the user.
# source ${PWD}/use-Kops.sh

# if [ "$0" = "$BASH_SOURCE" ]
# then
#     echo "$0: Please source this file."
#     echo "# source ${PWD}/use-Kops.sh"
#     exit 1
# fi

#Some collors for human friendly
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 2`
RESET=`tput sgr0`

# Get the name of OS
OS_NAME=`cat /etc/os-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/"//g'`


# Change this if you would like to move your Kops home folder
KOPS_HOME='/usr/local/bin'
if curl --version >/dev/null; then
  # Getting all available versions from github .
  foundHelmVersions=$(curl -s 'https://api.github.com/repos/kubernetes/kops/releases'  | jq '.[].tag_name' | grep -Ev 'beta|alpha|rc'| sed 's/"//g')
  echo "$release"
  # If releases founded script will continue
  if [[ $foundHelmVersions ]]; then
    if wget --version > /dev/null; then
      # If OS type is Apple then script will provide available versions
      if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e  "$foundHelmVersions"
        if kops version  > /dev/null; then
          INSTALLED_KOPS=$(kops version | awk '{print $2}')
          echo -e "${GREEN}Current version: ${INSTALLED_KOPS}${RESET}"
        fi
        echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read SELLECTEDVERSION
        if [[ "$SELLECTEDVERSION" ]]; then
          echo -e "$(tput setaf 2)#--- Downloading kops for this $OS_NAME. ---#"
          wget -q --show-progress --progress=bar:force  "https://github.com/kubernetes/kops/releases/download/${SELLECTEDVERSION}/kops-darwin-amd64" -O "./kops" 2>&1

          # after user select existing Kops version
          mv "./kops" "$KOPS_HOME/kops" && chmod +x "$KOPS_HOME/kops"
          echo -e "${GREEN}#---    Moving Kops to bin folder.      ---#${RESET}"
        else
          echo -e "${RED}#---    Error Kops versions is not selected.      ---#${RESET}"
        fi
      # If OS type is Linux then script will provide available versions
      elif [[ "$OS_NAME" == "Ubuntu"* ]]; then
        echo -e  "$foundHelmVersions"
          if kops version  > /dev/null; then
            INSTALLED_KOPS=$(kops version | awk '{print $2}')
            echo -e "${GREEN}Current version: ${INSTALLED_KOPS}${RESET}"
          fi
          echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read SELLECTEDVERSION
          if [[ "$SELLECTEDVERSION" ]]; then
            echo -e "$(tput setaf 2)#--- Downloading kops for this $OS_NAME. ---#"
            wget -q --show-progress --progress=bar:force  "https://github.com/kubernetes/kops/releases/download/${SELLECTEDVERSION}/kops-linux-amd64" -O "./kops" 2>&1
            
            # after user select existing Kops version
            sudo mv "./kops" "$KOPS_HOME/kops" && sudo chmod +x "$KOPS_HOME/kops"
            echo -e "${GREEN}#---    Moving Kops to bin folder.      ---#${RESET}"
          else
            echo -e "${RED}#---    Error Kops versions is not selecrted.      ---#${RESET}"
          fi
      # If OS type is Linux then script will provide available versions
      elif [[ "$OS_NAME" == "CentOS"* ]]; then
          echo -e  "$foundHelmVersions"
          if kops version  > /dev/null; then
            INSTALLED_KOPS=$(kops version | awk '{print $2}')
            echo -e "${GREEN}Current version: ${INSTALLED_KOPS}${RESET}"
          fi
          echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read SELLECTEDVERSION
          if [[ "$SELLECTEDVERSION" ]]; then
            echo -e "$(tput setaf 2)#--- Downloading kops for this $OS_NAME. ---#"
            curl -LO --progress-bar  "https://github.com/kubernetes/kops/releases/download/${SELLECTEDVERSION}/kops-linux-amd64" 2>&1
            
            # after user select existing Kops version
            sudo mv "./kops-linux-amd64" "$KOPS_HOME/kops" && sudo chmod +x "$KOPS_HOME/kops"
            echo -e "${GREEN}#---    Moving Kops to bin folder.      ---#${RESET}"
          else
            echo -e "${RED}#---    Error Kops versions is not selected.      ---#${RESET}"
          fi
      else
        echo "Sorry this script does not support $OS_NAME"
      fi
    else
      echo -e "${RED}#---    Error wget command not found.      ---#${RESET}"
      exit 1
    fi
  else
    echo -e "${RED}#--- Error Kops versions not found or connections issue. ---#${RESET}"
    exit 1
  fi
else
  echo -e "${RED}#--- Error curl command not found. ---#${RESET}"
  exit 1
fi











