# slack-notification
This action creates a docker container that notifies Slack users when they're requested to review a pull request. The `entrypoint.sh` script pulls a YAML formatting mapping file from S3 in order to map GitHub users to their respective Slack channels. GitHub teams and users can be specified in the mapping file. 

# Usage

## Action Workflow Example
See [example.yml](.github/workflows/example.yml)
```yaml
name: Slack Notification

on:
    pull_request:
        types:
            - review_requested

jobs:
  notify_slack:
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

        - name: Slack Message
          id: slack_message
          run: |
            slack_message="A Pull Request has been created for your approval
            PR Link: ${{ github.event.pull_request.html.url}}"

            echo 'slack-message<<EOF' >> $GITHUB_OUTPUT
            echo "$slack_message" >> $GITHUB_OUTPUT
            echo 'EOF' >> $GITHUB_OUTPUT

        - name: Notify Slack
          uses: kapost/slack-notification
          env:
            S3_URL: s3://my-bucket/path/to/mapping.yml
            PAT_TOKEN: ${{ secrets.PAT_TOKEN }}
            PR_NUMBER: ${{ github.event.pull_request.number }}
            GITHUB_REPO: kapost/slack-notification
            PR_MESSAGE: ${{ steps.slack_message.outputs.slack-message }}
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
  thatsnotamuffin: # <-- GitHub username
    slack_username: '"@thatsnotamuffin"' # <-- Slack Channel
  muffin1:
    slack_username: '"@muffin1"'
  muffin2:
    slack_username: '"@muffin2"'
  muffin-team: # <-- GitHub team
    slack_username: '"#muffin-chat"' # <-- Slack Channel
```

# Versions
## v1
This version only supports Incoming WebHooks custom integrations. This is a legacy custom integration in Slack. Later this action will be updated to support mapping users and channels to individual Webhook URL
