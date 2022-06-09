#!/bin/bash

# Author <sadykovfarkhod@gmail.com>
# Modifier <nenf@yahoo.com>
# Script to download terraform and set up for the user.
# source ${PWD}/get-terraform.sh

# if [ "$0" = "$BASH_SOURCE" ]
# then
#     echo "$0: Please source this file."
#     echo "# source ${PWD}/get-terraform.sh"
#     exit 1
# fi

#Some collors for human friendly
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 2)
RESET=$(tput sgr0)


# Get the name of OS
OS_NAME=$( grep "PRETTY_NAME" /etc/os-release | sed 's/PRETTY_NAME=//g' | sed 's/"//g')

# Change this if you would like to move your terraform home folder
TERRAFORM_HOME='/usr/local/bin'
if curl --version >/dev/null; then
  # Getting all available versions from hashicorp.
  release=$(curl --connect-timeout 3 -s -X GET "https://releases.hashicorp.com/terraform/")
  foundTerraformVersions=$(echo "$release" | awk -F '/' '{print $3}' | grep -v '\s'  | grep -vE 'rc|beta|alpha|oci' |  sed  '/^$/d;' |grep -i terraform |cut -d'"' -f1 | head -n 50)
  echo "$foundTerraformVersions"
  # If releases founded script will continue
  if [[ -n $foundTerraformVersions ]]; then
    if wget --version > /dev/null; then
      # If OS type is Apple then script will provide available versions
      if [[ "$OSTYPE" == "darwin"* ]]; then
          echo -e  "$foundTerraformVersions"
          if terraform -version > /dev/null; then
            INSTALLED_TERRAFORM=$(terraform -version  | head -n1   | awk '{print $2}')
            echo -e "${GREEN}Current version: ${INSTALLED_TERRAFORM}${RESET}"
          fi
          echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read -r SELLECTEDVERSION
          if [[ -n "$SELLECTEDVERSION" ]]; then
            echo -e "$(tput setaf 2)#--- Downloading terraform for this $OSTYPE. ---#"
            wget -q --show-progress --progress=bar:force  "https://releases.hashicorp.com/terraform/${SELLECTEDVERSION}/terraform_${SELLECTEDVERSION}_darwin_amd64.zip" 2>&1

            # after user select existing terraform version
            echo -e "${GREEN}#---    Moving terraform to bin folder.      ---#${RESET}"
            unzip "terraform_${SELLECTEDVERSION}_darwin_amd64.zip" && /bin/mv "./terraform" "$TERRAFORM_HOME/terraform"
            rm -rf "terraform_${SELLECTEDVERSION}_darwin_amd64.zip"
          else
            echo -e "${RED}#---    Error Terraform versions is not selected.      ---#${RESET}"
          fi
      # If OS type is Linux then script will provide available versions
      elif [[ "$OS_NAME" == "Ubuntu"* ]]; then
          echo -e  "$foundTerraformVersions"
          if terraform -version > /dev/null; then
            INSTALLED_TERRAFORM=$(terraform -version  | head -n1 | awk '{print $2}')
            echo -e "${GREEN}Current version: ${INSTALLED_TERRAFORM}${RESET}"
          fi
          read -p -r "${GREEN}Please sellect one version to download: ${RESET}" SELLECTEDVERSION
          if [[ -n "$SELLECTEDVERSION" ]]; then
            echo -e "$(tput setaf 2)#--- Downloading terraform for this $OS_NAME. ---#"
            wget -q --show-progress --progress=bar:force   "https://releases.hashicorp.com/terraform/${SELLECTEDVERSION}/terraform_${SELLECTEDVERSION}_linux_amd64.zip" 2>&1

            # after user select existing terraform version
            echo -e "${GREEN}#---    Moving terraform to bin folder.      ---#${RESET}"
            unzip "terraform_${SELLECTEDVERSION}_linux_amd64.zip" && sudo mv "./terraform" "$TERRAFORM_HOME/terraform"
            rm -rf "terraform_${SELLECTEDVERSION}_linux_amd64.zip"
          else
            echo -e "${RED}#---    Error terraform versions is not selected.      ---#${RESET}"
          fi
      # If OS type is Linux then script will provide available versions
      elif [[ "$OS_NAME" == "CentOS"* ]]; then
          echo -e  "$foundTerraformVersions"
          if terraform -version > /dev/null; then
            INSTALLED_TERRAFORM=$(terraform -version  | head -n1 | awk '{print $2}')
            echo -e "${GREEN}Current version: ${INSTALLED_TERRAFORM}${RESET}"
          fi
          echo -e "${GREEN}Please sellect one version to download: ${RESET}"  && read -r SELLECTEDVERSION
          #read -p -r "${GREEN}Please sellect one version to download: ${RESET}" SELLECTEDVERSION
          if [[ -n "$SELLECTEDVERSION" ]]; then
            echo -e "$(tput setaf 2)#--- Downloading terraform for this $OS_NAME. ---#"
            curl -LO --progress-bar "https://releases.hashicorp.com/terraform/${SELLECTEDVERSION}/terraform_${SELLECTEDVERSION}_linux_amd64.zip" 2>&1

            # after user select existing terraform version
            echo -e "${GREEN}#---    Moving terraform to bin folder.      ---#${RESET}"
            unzip "terraform_${SELLECTEDVERSION}_linux_amd64.zip" && sudo mv "./terraform" "$TERRAFORM_HOME/terraform"
            rm -rf "terraform_${SELLECTEDVERSION}_linux_amd64.zip"
          else
            echo -e "${RED}#---    Error terraform versions is not selected.      ---#${RESET}"
          fi
      # If OS type is Linux then script will provide available versions
      elif [[ "$OS_NAME" == "Debian"* ]]; then
          echo -e  "$foundTerraformVersions"
          if terraform -version > /dev/null; then
            INSTALLED_TERRAFORM=$(terraform -version  | head -n1 | awk '{print $2}')
            echo -e "${GREEN}Current version: ${INSTALLED_TERRAFORM}${RESET}"
          fi
          read -p -r "${GREEN}Please sellect one version to download: ${RESET}" SELLECTEDVERSION
          if [[ -n "$SELLECTEDVERSION" ]]; then
            echo -e "$(tput setaf 2)#--- Downloading terraform for this $OS_NAME. ---#"
            curl -LO --progress-bar "https://releases.hashicorp.com/terraform/${SELLECTEDVERSION}/terraform_${SELLECTEDVERSION}_linux_amd64.zip" 2>&1

            # after user select existing terraform version
            echo -e "${GREEN}#---    Moving terraform to bin folder.      ---#${RESET}"
            unzip "terraform_${SELLECTEDVERSION}_linux_amd64.zip" && sudo mv "./terraform" "$TERRAFORM_HOME/terraform"
            rm -rf "terraform_${SELLECTEDVERSION}_linux_amd64.zip"
          else
            echo -e "${RED}#---    Error terraform versions is not selected.      ---#${RESET}"
          fi
      fi
    else
      echo -e "${RED}#---    Error wget command not found.      ---#${RESET}"
      exit 1
    fi
  else
    echo -e "${RED}#--- Error Terraform versions not found or connections issue. ---#${RESET}"
    exit 1
  fi
else
  echo -e "${RED}#--- Error curl command not found. ---#${RESET}"
  exit 1
fi
