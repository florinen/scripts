#!/bin/bash

# Author <sadykovfarkhod@gmail.com>
# Modifier <nenf@yahoo.com>
# Script to download Helm and set up for the user.
# source ${PWD}/get-helm.sh

# if [ "$0" = "$BASH_SOURCE" ]
# then
#     echo "$0: Please source this file."
#     echo "# source ${PWD}/get-helm.sh"
#     exit 1
# fi




#Some collors for human friendly
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 2)
RESET=$(tput sgr0)

# Get the name of OS
OS_NAME=$( grep "PRETTY_NAME" /etc/os-release | sed 's/PRETTY_NAME=//g' | sed 's/"//g')

# Change this if you would like to move your helm home folder
HELM_HOME='/usr/local/bin'
if curl --version >/dev/null; then
  # Getting all available versions from github .
  foundHelmVersions=$(curl -s 'https://api.github.com/repos/helm/helm/releases'  | jq '.[].tag_name' | grep -Ev 'beta|alpha|rc'| sed 's/"//g')
  echo "$release"
  # If releases founded script will continue
  if [[ $foundHelmVersions ]]; then
    if wget --version > /dev/null; then
      # If OS type is Apple then script will provide available versions
      if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e  "$foundHelmVersions"
        if helm version --client > /dev/null; then
          INSTALLED_HELM=$(helm version --client  | awk '{print $2}' | cut -c 25-33 | sed 's/"//g')
          echo -e "${GREEN}Current version: ${INSTALLED_HELM}${RESET}"
        fi
        echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read -r SELLECTEDVERSION
        if [[ -n "$SELLECTEDVERSION" ]]; then
          echo -e "$(tput setaf 2)#--- Downloading Helm for this $OSTYPE. ---#"
          wget -q --show-progress --progress=bar:force  "https://get.helm.sh/helm-${SELLECTEDVERSION}-darwin-amd64.tar.gz" 2>&1
  
          # after user select existing helm version
          tar -xzvf "helm-${SELLECTEDVERSION}-darwin-amd64.tar.gz"
          mv "./darwin-amd64/helm" "$HELM_HOME/helm"
          rm -rf "helm-${SELLECTEDVERSION}-darwin-amd64.tar.gz"
          rm -rf "$PWD/linux-amd64" 2>/dev/null
          echo -e "${GREEN}#---    Moving Helm to bin folder.      ---#${RESET}"
        else
          echo -e "${RED}#---    Error Helm versions is not selected.      ---#${RESET}"
        fi 
          echo -e "${GREEN}--->    Helm version recorded.    <---${RESET}"
          helm version --client  | awk '{print $2}' | cut -c 25-33 | sed 's/"//g' >> .helm_record.txt
      # If OS type is Linux then script will provide available versions
      elif [[ "$OS_NAME" == "Ubuntu"* ]]; then
        echo -e  "$foundHelmVersions"
        if helm version --client > /dev/null; then
          INSTALLED_HELM=$(helm version --client  | awk '{print $2}' | cut -c 25-33 | sed 's/"//g')
          echo -e "${GREEN}Current version: ${INSTALLED_HELM}${RESET}"
        fi
        echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read -r SELLECTEDVERSION
        if [[ -n "$SELLECTEDVERSION" ]]; then
          echo -e "$(tput setaf 2)#--- Downloading Helm for this $OS_NAME. ---#"
          wget -q --show-progress --progress=bar:force  "https://get.helm.sh/helm-${SELLECTEDVERSION}-linux-amd64.tar.gz" 2>&1

          # after user select existing helm version
          tar -xzvf "helm-${SELLECTEDVERSION}-linux-amd64.tar.gz"
          sudo mv "./linux-amd64/helm" "$HELM_HOME/helm"
          sudo rm -rf "helm-${SELLECTEDVERSION}-linux-amd64.tar.gz"
          sudo rm -rf "$PWD/linux-amd64" 2>/dev/null
          echo -e "${GREEN}#---    Moving helm to bin folder.      ---#${RESET}"
        else
          echo -e "${RED}#---    Error helm versions is not selected.      ---#${RESET}"
        fi
        echo -e "${GREEN}--->    Helm version recorded.    <---${RESET}"
        helm version --client  | awk '{print $2}' | cut -c 25-33 | sed 's/"//g' >> .helm_record.txt
      # If OS type is Linux then script will provide available versions
      elif [[ "$OS_NAME" == "CentOS"* ]]; then
        echo -e  "$foundHelmVersions"
        if helm version --client > /dev/null; then
          INSTALLED_HELM=$(helm version --client  | awk '{print $2}' | cut -c 25-33 | sed 's/"//g')
          echo -e "${GREEN}Current version: ${INSTALLED_HELM}${RESET}"
        fi
        echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read -r SELLECTEDVERSION
        if [[ -n "$SELLECTEDVERSION" ]]; then
          echo -e "$(tput setaf 2)#--- Downloading Helm for this $OS_NAME. ---#"
          curl -LO --progress-bar  "https://get.helm.sh/helm-${SELLECTEDVERSION}-linux-amd64.tar.gz" 2>&1
 
          # after user select existing helm version
          tar -xzvf "helm-${SELLECTEDVERSION}-linux-amd64.tar.gz"
          sudo mv "./linux-amd64/helm" "$HELM_HOME/helm"
          sudo rm -rf "helm-${SELLECTEDVERSION}-linux-amd64.tar.gz"
          sudo rm -rf "$PWD/linux-amd64" 2>/dev/null
          echo -e "${GREEN}#---    Moving helm to bin folder.      ---#${RESET}"
        else
          echo -e "${RED}#---    Error helm versions is not selected.      ---#${RESET}"
        fi
        echo -e "${GREEN}--->    Helm version recorded.    <---${RESET}"
        helm version --client  | awk '{print $2}' | cut -c 25-33 | sed 's/"//g' >> .helm_record.txt
      # If OS type is Linux then script will provide available versions
      elif [[ "$OS_NAME" == "Debian"* ]]; then
        echo -e  "$foundHelmVersions"
        if helm version --client > /dev/null; then
          INSTALLED_HELM=$(helm version --client  | awk '{print $2}' | cut -c 25-33 | sed 's/"//g')
          echo -e "${GREEN}Current version: ${INSTALLED_HELM}${RESET}"
        fi
        echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read -r SELLECTEDVERSION
        if [[ -n "$SELLECTEDVERSION" ]]; then
          echo -e "$(tput setaf 2)#--- Downloading Helm for this $OS_NAME. ---#"
          curl -LO --progress-bar  "https://get.helm.sh/helm-${SELLECTEDVERSION}-linux-amd64.tar.gz" 2>&1
 
          # after user select existing helm version
          tar -xzvf "helm-${SELLECTEDVERSION}-linux-amd64.tar.gz"
          sudo mv "./linux-amd64/helm" "$HELM_HOME/helm"
          sudo rm -rf "helm-${SELLECTEDVERSION}-linux-amd64.tar.gz"
          sudo rm -rf "$PWD/linux-amd64" 2>/dev/null
          echo -e "${GREEN}#---    Moving helm to bin folder.      ---#${RESET}"
        else
          echo -e "${RED}#---    Error helm versions is not selected.      ---#${RESET}"
        fi
        echo -e "${GREEN}--->    Helm version recorded.    <---${RESET}"
        helm version --client  | awk '{print $2}' | cut -c 25-33 | sed 's/"//g' >> .helm_record.txt
      fi
    else
      echo -e "${RED}#---    Error wget command not found.      ---#${RESET}"
      exit 1
    fi
  else
    echo -e "${RED}#--- Error helm versions not found or connections issue. ---#${RESET}"
    exit 1
  fi
else
    echo -e "${RED}#--- Error curl command not found. ---#${RESET}"
    exit 1
fi

