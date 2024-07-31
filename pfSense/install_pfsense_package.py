
import requests
import paramiko
import os

# GitHub repository details
REPO = "jaredhendrickson13/pfsense-api"
API_URL = f"https://api.github.com/repos/{REPO}/releases"

# SSH details for pfSense
PF_HOST = "pfsense.varu.local"
PF_USER = "admin"
PKG = "pfSense-2.7.2-pkg-RESTAPI.pkg"
PF_SSH_KEY = os.path.expanduser('~/.ssh/id_ed25519')

def fetch_releases():
    response = requests.get(API_URL)
    releases = response.json()
    for release in reversed(releases):
        print(f"{release['tag_name']} {release['name']} {release['html_url']}")

def install_package(version):
    download_url = f"https://github.com/{REPO}/releases/download/{version}/{PKG}"

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(PF_HOST, username=PF_USER, key_filename=PF_SSH_KEY)

    commands = f"""
    fetch -4 {download_url} -o /tmp/{PKG} && \
    pkg-static -C /dev/null add /tmp/{PKG} && \
    rm /tmp/{PKG}
    """

    stdin, stdout, stderr = ssh.exec_command(commands)
    print(stdout.read().decode())
    print(stderr.read().decode())

    ssh.close()

def main():
    print("Available releases:")
    fetch_releases()

    version = input("Enter the version you want to install: ")
    install_package(version)

if __name__ == "__main__":
    main()



# #!/bin/bash

# # GitHub repository details
# REPO="jaredhendrickson13/pfsense-api"
# API_URL="https://api.github.com/repos/${REPO}/releases"

# # SSH details for pfSense
# PF_HOST="your_pfsense_host"
# PF_USER="your_pfsense_user"
# PF_SSH_KEY="path_to_your_ssh_key"  # Path to your SSH private key if using key-based authentication

# # Function to fetch and display releases
# fetch_releases() {
#     curl -s "${API_URL}" | jq -r '.[] | "\(.tag_name) \(.name) \(.html_url)"'
# }

# # Function to download and install the selected version on pfSense
# install_package() {
#     local version=$1
#     local download_url="https://github.com/${REPO}/releases/download/${version}/your_package.txz"

#     ssh -t -i "${PF_SSH_KEY}" "${PF_USER}@${PF_HOST}" << EOF
#     fetch -4 ${download_url} -o /tmp/package.txz && \
#     pkg-static -C /dev/null add /tmp/package.txz && \
#     rm /tmp/package.txz
# EOF
# }

# # Fetch and display available releases
# echo "Available releases:"
# fetch_releases

# # Prompt the user to select a version
# echo -n "Enter the version you want to install: "
# read version

# # Install the selected package version on pfSense
# install_package "$version"