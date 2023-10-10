# slack-notification
This action creates a docker container that notifies Slack users when they're requested to review a pull request. The `entrypoint.sh` script pulls a YAML formatting mapping file from S3 in order to map GitHub users to their respective Slack channels. GitHub teams and users can be specified in the mapping file. A `NOTIFIED_USERS_URL` is specified in order to store or read users that have already been notified. This is to be stored in an S3 bucket similar to the `MAPPING_URL`.

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
            MAPPING_URL: s3://my-bucket/path/to/mapping.yml
            NOTIFIED_USERS_URL: s3://my-bucket/pull-requests/app/${{ github.event.pull_request.number }}/notified-users.txt
            PAT_TOKEN: ${{ secrets.PAT_TOKEN }}
            PR_NUMBER: ${{ github.event.pull_request.number }}
            GITHUB_REPO: kapost/slack-notification
            PR_MESSAGE: "A Pull Request has been created for your approval by @${{ github.actor }}\nPR Title: ${{ github.event.pull_request.title }}\nPR Link: ${{ github.event.pull_request.html_url}}"
```

### Variables
| Variable | Usage | Example |
| ---- | ---- | ---- |
| `MAPPING_URL` | URL of the S3 mapping file | s3://my-bucket/path/to/mapping.yml |
| `NOTIFIED_USERS_URL` | URL of the notified users file - does not have to exist but must be specified in order to create one | s3://my-bucket/pull-requests/app/${{ github.event.pull_request.number }}/notified-users.txt |
| `PAT_TOKEN` | Personal Access Token with permissions to read reviewers and pull requests | ghp_MyTokenCreatedInGithub |
| `PR_NUMBER` | Pull Request Number - Advised to pull from the Pull Request event | 1 |
| `GITHUB_REPO` | GitHub Owner and Repository | kapost/slack-notification |
| `PR_MESSAGE` | Message to send to the Slack user(s) or channel(s) | "Hello World!" |

## Mapping YAML Example
S3 [user-mapping.yml](user-mapping.yml)
```yaml
github_to_slack_mapping:
  thatsnotamuffin: # <-- GitHub User
    slack_username: "@thatsnotamuffin" # <-- Slack User
    slack_url: "https://hooks.slack.com/services/ABCD/ABCD1234" # <-- WebHook URL
  kapuser1:
    slack_username: "@kapuser1"
    slack_url: "https://hooks.slack.com/services/ABCD/ABCD1235"
  kapuser2:
    slack_username: "@kapuser2"
    slack_url: "https://hooks.slack.com/services/ABCD/ABCD1236" 
  kapuser-team:
    slack_username: "#kapuser-chat" # <-- Slack Channel
    slack_url: "https://hooks.slack.com/services/ABCD/ABCD1237" # <-- WebHook URL

```

# Versions
## v1
This version only supports Incoming WebHooks custom integrations. This is a legacy custom integration in Slack. Later this action will be updated to support mapping users and channels to individual Webhook URLs. This version will send repeated notifications to users that have not approved the pull request and channels (if applicable) whenever they requested reviewers is updated. This can be a bit spammy but I'm leaving the `v1` version in place in case there is some use case for it in which `v2` and `v3` do not work.

## v2
Added support to prevent notifying the same user multiple times if other users are requested to review. This is done by adding the `NOTIFIED_USERS_URL` argument. This argument must be specified in order to read or create the file of users that have already been notified. As of the moment, this loops over the file denoted by new lines. 

It is important that the `NOTIFIED_USERS_URL` argument is unique to each pull request, otherwise conflicts may occur between multiple pull requests trying to read the same user file. In the example above this is done by using a `pull-requests/app1` directory, then each `notified-users.txt` file are stored within directories that are separated by their pull request number that is generated from the `github pull request event`.

Example Formatting in a `notified-users.txt` file
```txt
kapuser1
kapuser2
kapuser-team
```

## v3
Added support for App integration that requires each user and channel have a separate webhook. There is a bit of overlap with the [GitHub Slack App](https://kapost.slack.com/apps/A01BP7R4KNY-github?tab=more_info). However, this action is meant to notify users and channels directly when added to a pull request rather than make a request to subscribe to multiple repositories. 

### General
You will need to create a slack app and set the incoming webhook URLs. Follow the instructions [here](https://api.slack.com/messaging/webhooks) for more information.

Afterwards, you will need to create or update (if this action was previously used) your user mapping yaml file. An argument of `slack_url` needs to be added to each user to accommodate the new webhooks. There isn't an arbitrary requirement for each `slack_url` to be unique, it's up to your discretion on the webhook urls used. 

```yaml
github_to_slack_mapping:
  thatsnotamuffin: # <-- GitHub User
    slack_username: "@thatsnotamuffin" # <-- Slack User
    slack_url: "https://hooks.slack.com/services/ABCD/ABCD1234" # <-- Incoming WebHook URL
```
