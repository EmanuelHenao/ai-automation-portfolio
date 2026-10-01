#!/usr/bin/env bash
# Sends every sample lead to the workflow and shows what happened.
#   ./01-ai-lead-qualification/scripts/demo.sh          run the demo
#   ./01-ai-lead-qualification/scripts/demo.sh --reset  clear demo data first (DB + CRM)
set -euo pipefail
cd "$(dirname "$0")/../.."
set -a; . ./.env; set +a

URL=${LEAD_WEBHOOK_URL:-http://localhost:5678/webhook/lead-intake}
SAMPLES=01-ai-lead-qualification/samples
psql() { docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$@"; }
title() { printf '\n\033[1;36m━━ %s\033[0m\n' "$*"; }

if [[ "${1:-}" == "--reset" ]]; then
  title "Resetting demo data"
  ./scripts/clear-channel.sh sales-alerts ops-alerts
  curl -s -X DELETE http://localhost:8025/api/v1/messages -o /dev/null
  psql -qc "TRUNCATE leads RESTART IDENTITY; DELETE FROM execution_log WHERE project = '01-lead-qualification'; TRUNCATE automation_errors RESTART IDENTITY;"
  ids=$(curl -s "http://localhost:8080/api/v2/tables/$NOCODB_LEADS_TABLE_ID/records?fields=Id&limit=1000" \
    -H "xc-token: $NOCODB_API_TOKEN" | python3 -c "import sys,json; print(json.dumps([{'Id': r['Id']} for r in json.load(sys.stdin)['list']]))")
  [[ "$ids" != "[]" ]] && curl -s -X DELETE "http://localhost:8080/api/v2/tables/$NOCODB_LEADS_TABLE_ID/records" \
    -H "xc-token: $NOCODB_API_TOKEN" -H 'Content-Type: application/json' -d "$ids" >/dev/null
  echo "done"
fi

send() { # send LABEL FILE [TOKEN]
  title "$1"
  curl -s -w '  → HTTP %{http_code}\n' -X POST "$URL" \
    -H "X-Webhook-Token: ${3-$WEBHOOK_TOKEN}" -H 'Content-Type: application/json' -d @"$2"
}

send "Request without a valid token (expect 401)" "$SAMPLES/01-hot-lead.json" "wrong-token"
send "Invalid payload (expect 400 with field errors)" "$SAMPLES/05-invalid.json"
send "Hot lead (expect sales alert + email + CRM)" "$SAMPLES/01-hot-lead.json"
send "Warm lead (expect CRM stage 'Qualify')" "$SAMPLES/02-warm-lead.json"
send "Cold lead (expect CRM stage 'Nurture')" "$SAMPLES/03-cold-lead.json"
send "Spam (expect stored only, no CRM)" "$SAMPLES/04-spam.json"
send "Prompt injection attempt (expect a low score)" "$SAMPLES/06-prompt-injection.json"
send "Same hot lead again (expect duplicate, no AI cost)" "$SAMPLES/01-hot-lead.json"

sleep 3
title "Leads in PostgreSQL"
psql -c "SELECT id, full_name, score, category, route, left(next_action, 60) AS next_action FROM leads ORDER BY id;"
title "Execution log"
psql -c "SELECT status, detail, latency_ms, prompt_tokens + completion_tokens AS tokens FROM execution_log WHERE project = '01-lead-qualification' ORDER BY id;"

cat <<EOF

Check the results visually:
  CRM (NocoDB)          http://localhost:8080
  Alerts (Mattermost)   http://localhost:8065/acme/channels/sales-alerts
  Email (Mailpit)       http://localhost:8025
  Executions (n8n)      http://localhost:5678
EOF
