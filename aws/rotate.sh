#!/bin/bash

profile=''

print_usage() {
	echo "Usage: ./rotate.sh [-p profile]"
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
RENEWAL_TIME="90"
DATE_NOW=$(date "+%F")
# Check if jq is installed
if ! hash jq; then
	echo "Can't find jq. Is it installed?"
	exit 1
fi

# Check if aws cli is installed
if ! hash aws; then
	echo "Can't find aws cli. Is it installed?"
	exit 1
fi

IDENTITY=$(aws sts get-caller-identity --profile "$PROFILE")

STATUS=$?

if [ "$STATUS" -gt 0 ]; then
	echo "Couldn't get caller identity"
	exit 1
fi

echo "Renewing access keys as $IDENTITY"

read -r KEY_COUNT < <(aws iam list-access-keys --profile "$PROFILE" | jq '.AccessKeyMetadata | length')

if [ -z "$KEY_COUNT" ]; then
	echo "Couldn't retrieve keys."
	exit 1
fi
# Get the Creation Date of the access keys:
read -r ACCESS_KEY_CREATED_DATE < <(aws iam list-access-keys --profile "$PROFILE" | jq -r '.AccessKeyMetadata[0].CreateDate' )
COUNT_DAYS=$(( ($( date -u -d "$DATE_NOW" "+%s") - $(date -u -d "$ACCESS_KEY_CREATED_DATE" "+%s")) /86400  ))
echo "$COUNT_DAYS days"
# If you have multiple keys, get the oldest and delete if it's status is INACTIVE, but ONLY if is older then 90 days:
if [ "$KEY_COUNT" -gt 1 ]; then
	echo "More than one access key present."
	read -r DEL_ACCESS_KEY < <(aws iam list-access-keys --profile "$PROFILE" | jq -r '.AccessKeyMetadata[0].AccessKeyId')
    read -r STATUS_ACCESS_KEY < <(aws iam list-access-keys --profile "$PROFILE" | jq -r '.AccessKeyMetadata[0].Status')
    if [[ "$COUNT_DAYS" -gt "$RENEWAL_TIME" ]]; then
		if [[ "$DEL_ACCESS_KEY" ]] && [[ "$STATUS_ACCESS_KEY" = "Inactive" ]]; then
			aws iam delete-access-key --access-key-id "$DEL_ACCESS_KEY" --profile "$PROFILE"

			STATUS=$?
			if [[ "$STATUS" -eq 0 ]]; then
				echo "Access key: $DEL_ACCESS_KEY for $PROFILE successfully deleted!!"
			
			fi
			
		else
			echo "Couldn't delete keys: $DEL_ACCESS_KEY,  key status is: $STATUS_ACCESS_KEY"
			exit 1
		fi
	else
		echo "Keys $DEL_ACCESS_KEY need to be older then 90 days. Current age is: $COUNT_DAYS days"
		exit 1
	fi
fi

read -r OLD_ACCESS_KEY < <(aws iam list-access-keys --profile "$PROFILE" | jq -r '.AccessKeyMetadata[0].AccessKeyId')


read -r ACCESS_KEY_ID SECRET_KEY < <(aws iam create-access-key --profile "$PROFILE" | jq -r '.AccessKey | "\(.AccessKeyId) \(.SecretAccessKey)"')

STATUS=$?

if [ "$STATUS" -gt 0 ]; then
	echo "Couldn't create key"
	exit 1
fi

aws iam update-access-key --access-key-id "$OLD_ACCESS_KEY" --status Inactive --profile "$PROFILE"
aws iam list-access-keys --profile "$PROFILE"
aws configure set aws_access_key_id "$ACCESS_KEY_ID" --profile "$PROFILE"
aws configure set aws_secret_access_key "$SECRET_KEY" --profile "$PROFILE"
if [[ "$DEL_ACCESS_KEY" ]]; then

    echo "Deleted Inactive access key $DEL_ACCESS_KEY for profile $PROFILE"
fi
if [[ "$ACCESS_KEY_ID" ]]; then

    echo "New access key ID: $ACCESS_KEY_ID"
fi
