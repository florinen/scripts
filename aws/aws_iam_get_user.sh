#!/bin/bash

# exit when the command fails
set -o errexit;

# exit when try to use undeclared var
set -o nounset;
profile=''

print_usage() {
	echo "Usage: ./aws_iam_user.sh.sh [-p profile]"
}

while getopts 'p:' flag; do
	case "${flag}" in
	p) profile="${OPTARG}" ;;
	*)
		print_usage
		exit 1
		;;
	esac
done
PROFILE=${profile:-default}

accessKeyToSearch=${3?"Usage: bash $0 AccessKeyId"}

for username in $(aws iam list-users --profile "$PROFILE" --query 'Users[*].UserName' --output text); do
	for accessKeyId in $(aws iam list-access-keys --profile "$PROFILE" --user-name "$username" --query 'AccessKeyMetadata[*].AccessKeyId' --output text); do
		if [ "$accessKeyToSearch" = "$accessKeyId" ]; then
			echo "$username";
			break;
		fi;
	done;
done;