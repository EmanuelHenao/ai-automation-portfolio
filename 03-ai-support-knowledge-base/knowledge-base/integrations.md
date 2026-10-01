# Integrations and API

Integrations are available on the Pro and Business plans.

## Native integrations
- **Slack**: get task notifications in a channel and create tasks with the /taskpilot command.
- **Google Calendar and Outlook**: two-way sync of task due dates.
- **GitHub and GitLab**: link pull requests and commits to tasks; tasks move to Done when the pull request is merged.
- **Google Drive, Dropbox and OneDrive**: attach files from cloud storage.
- **Zapier and Make**: connect TaskPilot to more than 5,000 other apps.

## REST API
The REST API lets you read and write projects, tasks, comments and members. Create a personal API token in **Settings > Developer > API tokens**. Rate limits are 100 requests per minute per token on Pro and 300 requests per minute on Business. Requests above the limit receive HTTP 429 with a Retry-After header.

## Webhooks
Webhooks send an HTTP POST to your URL when tasks are created, updated, completed or commented on. Each request is signed with an HMAC-SHA256 signature in the X-TaskPilot-Signature header. Failed deliveries are retried up to 5 times with exponential backoff.

## Integrations we don't offer
If you need a tool that is not listed here, you can usually connect it through Zapier, Make or the API.
