#!/usr/bin/env bash
# Deletes every post in the given Mattermost channels of team "acme" (used by the demo --reset options).
#   ./scripts/clear-channel.sh sales-alerts ops-alerts
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

MM=http://localhost:8065/api/v4
TOKEN=$(curl -si -X POST "$MM/users/login" -H 'Content-Type: application/json' \
  -d "{\"login_id\":\"admin\",\"password\":\"$ADMIN_PASSWORD\"}" | awk -F': ' 'tolower($1)=="token" {print $2}' | tr -d '\r')
[[ -n "$TOKEN" ]] || { echo "✗ Could not log in to Mattermost" >&2; exit 1; }

for channel in "$@"; do
  cid=$(curl -s "$MM/teams/name/acme/channels/name/$channel" -H "Authorization: Bearer $TOKEN" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))")
  [[ -n "$cid" ]] || continue
  for post in $(curl -s "$MM/channels/$cid/posts?per_page=200" -H "Authorization: Bearer $TOKEN" \
      | python3 -c "import sys,json; print(' '.join(json.load(sys.stdin).get('order', [])))"); do
    curl -s -o /dev/null -X DELETE "$MM/posts/$post" -H "Authorization: Bearer $TOKEN"
  done
done
