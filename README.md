# slack-notification
This action creates a docker container that notifies Slack users when they're requested to review a pull request. The `entrypoint.sh` script pulls a YAML formatting mapping file from S3 in order to map GitHub users to their respective Slack channels. GitHub teams and users can be specified in the mapping file. 

# Usage

## Action Workflow Example
See [example.yml](.github/workflows/example.yml)
```yaml
name: Slack Notification

# This action is ran any time a reviewer is added to a pull request
on:
  pull_request:
    types:
      - review_requested

jobs:
  notify_slack:
    # Prevents multiple notifications going out when adding multiple reviewers after PR is opened
    concurrency:
        group: ${{ github.workflow }}-${{ github.ref }}
        cancel-in-progress: true
    runs-on: ubuntu-latest
    steps:
        - name: Checkout
          uses: actions/checkout@v2

        - name: Sleep
          run: |
            echo "Sleeping for 10 seconds to allow a chance to prevent concurrent notifications"
            sleep 10
        
        - name: Configure AWS Credentials
          uses: aws-actions/configure-aws-credentials@v1
          with:
            aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
            aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
            aws-region: ${{ secrets.AWS_REGION }}

        - name: Notify Slack
          uses: kapost/slack-notification@script-update
          env:
            S3_URL: s3://my-bucket/path/to/mapping.yml
            PAT_TOKEN: ${{ secrets.PAT_TOKEN }}
            PR_NUMBER: ${{ github.event.pull_request.number }}
            GITHUB_REPO: kapost/slack-notification
            PR_MESSAGE: "A Pull Request has been created for your approval by @${{ github.actor }}\nPR Title: ${{ github.event.pull_request.title }}\nPR Link: ${{ github.event.pull_request.html_url}}"
            PR_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### Variables
| Variable | Usage | Example |
| ---- | ---- | ---- |
| S3_URL | URL of the S3 mapping file | s3://my-bucket/path/to/mapping.yml |
| PAT_TOKEN | Personal Access Token with permissions to read reviewers and pull requests | ghp_MyTokenCreatedInGithub |
| PR_NUMBER | Pull Request Number - Advised to pull from the Pull Request event | 1 |
| GITHUB_REPO | GitHub Owner and Repository | kapost/slack-notification |
| PR_MESSAGE | Message to send to the Slack user(s) or channel(s) | "Hello World!" |
| PR_WEBHOOK_URL | Slack Webhook URL | https://hooks.slack.com/services/ABCD/ABCD1234 |

## Mapping YAML Example
S3 [user-mapping.yml](user-mapping.yml)
```yaml
github_to_slack_mapping:
  thatsnotamuffin: # <-- GitHub User
    slack_username: "@thatsnotamuffin" # <-- Slack User
  muffin1:
    slack_username: "@muffin1"
  muffin2:
    slack_username: "@muffin2"
  muffin-team: # <-- GitHub Team
    slack_username: "#muffin-chat" # <-- Slack Channel
```

# Versions
## v1
This version only supports Incoming WebHooks custom integrations. This is a legacy custom integration in Slack. Later this action will be updated to support mapping users and channels to individual Webhook URL
