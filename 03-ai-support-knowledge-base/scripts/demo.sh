#!/usr/bin/env bash
# Indexes the knowledge base and runs the evaluation set against the support assistant.
#   ./03-ai-support-knowledge-base/scripts/demo.sh          run the demo
#   ./03-ai-support-knowledge-base/scripts/demo.sh --reset  clear questions, alerts and the index first
set -euo pipefail
cd "$(dirname "$0")/../.."
set -a; . ./.env; set +a

psql() { docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$@"; }
title() { printf '\n\033[1;36m━━ %s\033[0m\n' "$*"; }

if [[ "${1:-}" == "--reset" ]]; then
  title "Resetting demo data"
  ./scripts/clear-channel.sh support
  psql -qc "TRUNCATE support_questions, kb_chunks, kb_documents RESTART IDENTITY; DELETE FROM execution_log WHERE project = '03-support-rag';"
  echo "done"
fi

title "Indexing the knowledge base (unchanged articles are skipped)"
./03-ai-support-knowledge-base/scripts/ingest-kb.sh

title "Request without a question (expect 400)"
curl -s -w '  → HTTP %{http_code}\n' -X POST http://localhost:5678/webhook/support-ask \
  -H "X-Webhook-Token: $WEBHOOK_TOKEN" -H 'Content-Type: application/json' -d '{"question":""}'

title "Evaluation set: 8 answerable questions + 4 that must go to a human"
./03-ai-support-knowledge-base/scripts/eval.sh

title "Questions in PostgreSQL"
psql -c "SELECT id, status, left(coalesce(escalation_reason, ''), 40) AS reason, top_similarity AS similarity, left(question, 55) AS question
         FROM support_questions ORDER BY id;"

printf '\nCheck the results visually:\n'
printf '  Escalations (Mattermost)  http://localhost:8065/acme/channels/support\n'
printf '  Executions (n8n)          http://localhost:5678/workflow/supportAssist001/executions\n'
