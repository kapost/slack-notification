#!/bin/bash

set -xe

# Download Mapping File
aws s3 cp $S3_URL .
MAPPING_FILE=$(basename $S3_URL)

echo "$PAT_TOKEN" | gh auth login --with-token

# Gather Pull Request Info and Reviewers
pr_info=$(gh pr view $PR_NUMBER -R $GITHUB_REPO --json reviewRequests)
individual_reviewers=$(echo "$pr_info" | jq -r '.reviewRequests[] | select(.__typename == "User") | .login')
team_reviewers=$(echo "$pr_info" | jq -r '.reviewRequests[] | select(.__typename == "Team") | .slug')
combined_reviewers="${individual_reviewers} ${team_reviewers}"

reviewer_list=()
while read -r user; do
    reviewer_list+=("$user")
done <<< "$combined_reviewers"

# Parse YAML file and message users
for i in ${reviewer_list[@]}; do 
    slack_user=$(cat $MAPPING_FILE | shyaml get-value github_to_slack_mapping.$i.slack_username);
    curl -X POST -H 'Content-type: application/json' --data '{
        channel": '$slack_user',
        "text": "$PR_MESSAGE"
    }' $PR_WEBHOOK_URL;
done
