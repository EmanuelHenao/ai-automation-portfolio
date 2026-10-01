# Troubleshooting

## I can't log in
Use **Forgot password** on the login page; the reset link is valid for 1 hour. If your workspace uses SSO, you must log in with your company identity provider instead of a password. After 10 failed attempts the account is locked for 15 minutes.

## Notifications are not arriving
Check **Profile > Notifications** to make sure email or push notifications are enabled for that event. For email, check your spam folder and allow notifications@taskpilot.example. For the mobile app, make sure notifications are allowed in the phone settings and that you are logged in on only one account.

## CSV import fails
- The file must be UTF-8 encoded and use commas as separators.
- The first row must contain column headers; the "Task name" column is required.
- Maximum 10,000 rows and 20 MB per file.
- Dates must use the format YYYY-MM-DD.
The import screen shows the line number of the first error it finds.

## The board is slow
Boards with more than 2,000 visible tasks can feel slow. Archive completed tasks or use filters to show fewer tasks. Clearing the browser cache and updating to the latest browser version also helps.

## Status page
Check status.taskpilot.example for ongoing incidents and planned maintenance.
