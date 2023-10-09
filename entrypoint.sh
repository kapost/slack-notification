#!/bin/bash

set -xe

# Download Mapping File
aws s3 cp $MAPPING_URL .
MAPPING_FILE=$(basename $MAPPING_URL)

echo $PAT_TOKEN | gh auth login --with-token

# Gather Pull Request Info and Reviewers
pr_info=$(gh pr view $PR_NUMBER -R $GITHUB_REPO --json reviewRequests)
individual_reviewers=$(echo "$pr_info" | jq -r '.reviewRequests[] | select(.__typename == "User") | .login')
team_reviewers=$(echo "$pr_info" | jq -r '.reviewRequests[] | select(.__typename == "Team") | .slug')
combined_reviewers="${individual_reviewers} ${team_reviewers}"
       

reviewer_list=()
while read -r user; do
    reviewer_list+=("$user")
done <<< "$combined_reviewers"

# Check if notified users file already exists and if not, create the file and populate it with users in reviewer_list
if aws s3 ls "$NOTIFIED_USERS_URL" >/dev/null 2>&1; then
    # Notified users file exists, remove the already notified users from reviewer_list and update the file
    aws s3 cp $NOTIFIED_USERS_URL .
    NOTIFIED_USERS_FILE=$(basename $NOTIFIED_USERS_URL)

    while IFS= read -r username; do
        for i in "${!reviewer_list[@]}"; do
            if [[ ${reviewer_list[i]} == "$username" ]]; then
            unset 'reviewer_list[i]'
            fi
        done
    done < $NOTIFIED_USERS_FILE

    rm $NOTIFIED_USERS_FILE

    for i in ${reviewer_list[@]}; do
        echo $i >> $NOTIFIED_USERS_FILE
    done
else
    # Notified users file does not exist, populate the file with users in reviewer_list
    NOTIFIED_USERS_FILE=$(basename $NOTIFIED_USERS_URL)
    for i in ${reviewer_list[@]}; do
        echo $i >> $NOTIFIED_USERS_FILE
    done
fi

# Parse YAML file and message users
for i in ${reviewer_list[@]}; do 
    slack_user=$(cat $MAPPING_FILE | shyaml get-value github_to_slack_mapping.$i.slack_username);

    json_payload='{
        "channel": "'"${slack_user}"'",
        "text": "'"${PR_MESSAGE}"'"
    }'

    curl -X POST -H 'Content-type: application/json' --data "${json_payload}" $PR_WEBHOOK_URL;
done

# Upload notified users file
aws s3 cp $NOTIFIED_USERS_FILE $NOTIFIED_USERS_URL
