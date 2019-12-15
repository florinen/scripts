#!/bin/bash

# Author <sadykovfarkhod@gmail.com>
# Modifier <nenf@yahoo.com>
# Script to download kubectl and set up for the user.
# source ${PWD}/get-kubectl.sh

# if [ "$0" = "$BASH_SOURCE" ]
# then
#     echo "$0: Please source this file."
#     echo "# source ${PWD}/get-kubectl.sh"
#     exit 1
# fi

#Some collors for human friendly
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 2`
RESET=`tput sgr0`

# Get the name of OS
OS_NAME=`cat /etc/os-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/"//g'`

# Change this if you would like to move your kubectl home folder
KUBECTL_HOME='/usr/local/bin'
if curl --version >/dev/null; then
  # Getting all available versions from github .
  foundKubectlVersions=$(curl -s 'https://api.github.com/repos/kubernetes/kubernetes/releases'  | jq '.[].tag_name' | grep -Ev 'beta|alpha|rc'|  sed 's/"//g')
  echo "$release"
  # If releases founded script will continue
  if [[ $foundKubectlVersions ]]; then
    if wget --version > /dev/null; then
      # If OS type is Apple then script will provide available versions
      if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e  "$foundKubectlVersions"
        if kubectl version > /dev/null; then
          INSTALLED_KUBECTL=$(kubectl version  --client  | awk '{print $5}' | sed -nr 's/^GitVersion\s*:\s*"([^"]*)".*$/\1/p')
          echo -e "${GREEN}Current version: ${INSTALLED_KUBECTL}${RESET}"
        fi
        echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read SELLECTEDVERSION
        if [[ "$SELLECTEDVERSION" ]]; then
          echo -e "$(tput setaf 2)#--- Downloading kubectl for this $OSTYPE. ---#"
          wget -q --show-progress --progress=bar:force  "https://storage.googleapis.com/kubernetes-release/release/${SELLECTEDVERSION}/bin/darwin/amd64/kubectl" 2>&1

          # after user select existing kubectl version
          chmod +x kubectl && mv kubectl "${KUBECTL_HOME}/kubectl"
          echo -e "${GREEN}#---    Moving kubectl to bin folder.      ---#${RESET}"
        else
          echo -e "${RED}#---    Error Kubectl versions is not selected.      ---#${RESET}"
        fi
      # If OS type is Linux then script will provide available versions
      elif [[ "$OS_NAME" == "Ubuntu"* ]]; then
        echo -e  "$foundKubectlVersions"
        if kubectl version > /dev/null; then
          INSTALLED_KUBECTL=$(kubectl version  --client  | awk '{print $5}' | sed -nr 's/^GitVersion\s*:\s*"([^"]*)".*$/\1/p')
          echo -e "${GREEN}Current version: ${INSTALLED_KUBECTL}${RESET}"
        fi
        echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read SELLECTEDVERSION
        if [[ "$SELLECTEDVERSION" ]]; then
          echo -e "$(tput setaf 2)#--- Downloading kubectl for this $OS_NAME. ---#"
          wget -q --show-progress --progress=bar:force  "https://storage.googleapis.com/kubernetes-release/release/${SELLECTEDVERSION}/bin/linux/amd64/kubectl" 2>&1
         
          # after user select existing kubectl version
          chmod +x kubectl && sudo mv kubectl "${KUBECTL_HOME}/kubectl" 
          echo -e "${GREEN}#---    Moving kubectl to bin folder.      ---#${RESET}"
        else
          echo -e "${RED}#---    Error Kubectl versions is not selected.      ---#${RESET}"
        fi
      # If OS type is Linux then script will provide available versions
      elif [[ "$OS_NAME" == "CentOS"* ]]; then
        echo -e  "$foundKubectlVersions"
        if kubectl version > /dev/null; then
          INSTALLED_KUBECTL=$(kubectl version  --client  | awk '{print $5}' | sed -nr 's/^GitVersion\s*:\s*"([^"]*)".*$/\1/p')
          echo -e "${GREEN}Current version: ${INSTALLED_KUBECTL}${RESET}"
        fi
        echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read SELLECTEDVERSION
        if [[ "$SELLECTEDVERSION" ]]; then
          echo -e "$(tput setaf 2)#--- Downloading kubectl for this $OS_NAME. ---#"
          curl -LO --progress-bar  "https://storage.googleapis.com/kubernetes-release/release/${SELLECTEDVERSION}/bin/linux/amd64/kubectl" 2>&1
         
          # after user select existing kubectl version
          chmod +x kubectl && sudo mv kubectl "${KUBECTL_HOME}/kubectl" 
          echo -e "${GREEN}#---    Moving kubectl to bin folder.      ---#${RESET}"
        else
          echo -e "${RED}#---    Error Kubectl versions is not selected.      ---#${RESET}"
        fi
      fi
    else
      echo -e "${RED}#---    Error wget command not found.      ---#${RESET}"
      exit 1
    fi
  else
    echo -e "${RED}#--- Error Kubectl versions not found or connections issue. ---#${RESET}"
    exit 1
  fi
else
  echo -e "${RED}#--- Error curl command not found. ---#${RESET}"
  exit 1
fi
