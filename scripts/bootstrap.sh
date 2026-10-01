#!/usr/bin/env bash
# One-command setup of the local portfolio stack.
#   - starts the containers
#   - creates the admin user in n8n, Mattermost and NocoDB
#   - creates the Mattermost channels + incoming webhook and the NocoDB CRM table
#   - imports n8n credentials (from .env) and all workflows, and publishes them
# Safe to re-run: every step checks whether it was already done.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)

log() { printf '\033[1;34m▸ %s\033[0m\n' "$*"; }
ok() { printf '\033[1;32m✓ %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# ------------------------------------------------------------------ .env
if [[ ! -f .env ]]; then
  log "Creating .env from .env.example with random secrets"
  sed -e "s/change-me-postgres/$(openssl rand -hex 12)/" \
      -e "s/change-me-long-random-string/$(openssl rand -hex 32)/" \
      -e "s/change-me-webhook-token/$(openssl rand -hex 24)/" .env.example > .env
fi

set_env() { # set_env KEY VALUE  -> writes KEY=VALUE into .env
  if grep -q "^$1=" .env; then sed -i "s|^$1=.*|$1=$2|" .env; else echo "$1=$2" >> .env; fi
}
load_env() { set -a; . ./.env; set +a; }
load_env

[[ "${OPENAI_API_KEY:-}" == "sk-..." || -z "${OPENAI_API_KEY:-}" ]] && \
  printf '\033[1;33m! OPENAI_API_KEY is not set in .env — AI steps will fall back to manual review.\033[0m\n'

json() { python3 -c "import sys,json; d=json.load(sys.stdin); print($1)"; }

wait_for() { # wait_for NAME URL
  for _ in $(seq 1 60); do
    [[ "$(curl -s -o /dev/null -w '%{http_code}' "$2")" == "200" ]] && { ok "$1 is up"; return; }
    sleep 3
  done
  die "$1 did not start ($2)"
}

# ------------------------------------------------------------------ containers
log "Starting containers"
docker compose up -d --quiet-pull
wait_for n8n http://localhost:5678/healthz
wait_for Mattermost http://localhost:8065/api/v4/system/ping
wait_for NocoDB http://localhost:8080/api/v1/health
wait_for Extractor http://localhost:8000/health

# ------------------------------------------------------------------ database schemas
# Init scripts only run on an empty volume; re-apply them (all idempotent) so new projects get their tables
log "Applying database schemas"
for sql in infra/postgres/init/[1-9]*.sql; do
  docker compose exec -T postgres psql -q -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$sql" >/dev/null
done
ok "Schemas up to date"

# ------------------------------------------------------------------ n8n owner
if curl -s http://localhost:5678/rest/settings | json "d['data']['userManagement']['showSetupOnFirstLoad']" | grep -q True; then
  log "Creating n8n owner account"
  curl -sf -X POST http://localhost:5678/rest/owner/setup -H 'Content-Type: application/json' \
    -d "{\"email\":\"$ADMIN_EMAIL\",\"firstName\":\"Portfolio\",\"lastName\":\"Admin\",\"password\":\"$ADMIN_PASSWORD\"}" >/dev/null
fi
ok "n8n owner: $ADMIN_EMAIL"

# ------------------------------------------------------------------ Mattermost
mm() { docker compose exec -T mattermost mmctl --local "$@"; }
log "Configuring Mattermost (team acme, channels sales-alerts / ops-alerts / invoices)"
mm user create --email "$ADMIN_EMAIL" --username admin --password "$ADMIN_PASSWORD" --system-admin >/dev/null 2>&1 || true
mm team create --name acme --display-name "Acme Inc" >/dev/null 2>&1 || true
mm team users add acme admin >/dev/null 2>&1 || true
for ch in sales-alerts:"Sales Alerts" ops-alerts:"Ops Alerts" invoices:"Invoices"; do
  mm channel create --team acme --name "${ch%%:*}" --display-name "${ch#*:}" >/dev/null 2>&1 || true
  mm channel users add "acme:${ch%%:*}" admin >/dev/null 2>&1 || true
done
HOOK_ID=$(mm webhook list --json 2>/dev/null | python3 -c "
import sys,json
hooks=[h for h in (json.load(sys.stdin) or []) if h.get('display_name')=='n8n automations']
print(hooks[0]['id'] if hooks else '')" || true)
if [[ -z "$HOOK_ID" ]]; then
  HOOK_ID=$(mm webhook create-incoming --channel acme:sales-alerts --user admin \
    --display-name "n8n automations" --description "Alerts sent by n8n workflows" 2>/dev/null | awk '/^Id:/ {print $2}')
fi
[[ -n "$HOOK_ID" ]] || die "Could not create the Mattermost webhook"
set_env NOTIFY_WEBHOOK_URL "http://mattermost:8065/hooks/$HOOK_ID"
ok "Mattermost webhook ready"

# ------------------------------------------------------------------ NocoDB
NC=http://localhost:8080
log "Configuring NocoDB (base 'Sales CRM', table 'Leads')"
curl -s -X POST $NC/api/v1/auth/user/signup -H 'Content-Type: application/json' \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" >/dev/null || true
NC_AUTH=$(curl -sf -X POST $NC/api/v1/auth/user/signin -H 'Content-Type: application/json' \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" | json "d['token']")

if [[ -z "${NOCODB_API_TOKEN:-}" ]]; then
  NOCODB_API_TOKEN=$(curl -sf -X POST $NC/api/v1/tokens -H "xc-auth: $NC_AUTH" -H 'Content-Type: application/json' \
    -d '{"description":"n8n"}' | json "d['token']")
  set_env NOCODB_API_TOKEN "$NOCODB_API_TOKEN"
fi

if [[ -z "${NOCODB_LEADS_TABLE_ID:-}" ]]; then
  BASE_ID=$(curl -sf -X POST $NC/api/v2/meta/bases -H "xc-token: $NOCODB_API_TOKEN" -H 'Content-Type: application/json' \
    -d '{"title":"Sales CRM"}' | json "d['id']")
  NOCODB_LEADS_TABLE_ID=$(curl -sf -X POST "$NC/api/v2/meta/bases/$BASE_ID/tables" -H "xc-token: $NOCODB_API_TOKEN" \
    -H 'Content-Type: application/json' -d @"$ROOT/infra/nocodb/leads-table.json" | json "d['id']")
  set_env NOCODB_LEADS_TABLE_ID "$NOCODB_LEADS_TABLE_ID"
fi
ok "NocoDB CRM table: $NOCODB_LEADS_TABLE_ID"

# ------------------------------------------------------------------ n8n credentials + workflows
load_env
log "Recreating n8n with the new environment"
docker compose up -d n8n >/dev/null 2>&1
wait_for n8n http://localhost:5678/healthz

log "Importing n8n credentials (encrypted by n8n on import)"
CREDS=$(mktemp)
trap 'rm -f "$CREDS"' EXIT
cat > "$CREDS" <<EOF
[
  {"id": "pgPortfolio00001", "name": "Portfolio Postgres", "type": "postgres",
   "data": {"host": "postgres", "port": 5432, "database": "$POSTGRES_DB", "user": "$POSTGRES_USER",
            "password": "$POSTGRES_PASSWORD", "ssl": "disable"}},
  {"id": "smtpMailpit00001", "name": "Mailpit SMTP", "type": "smtp",
   "data": {"host": "mailpit", "port": 1025, "secure": false, "disableStartTls": true, "user": "", "password": ""}}
]
EOF
docker compose cp "$CREDS" n8n:/tmp/credentials.json >/dev/null 2>&1
docker compose exec -T n8n n8n import:credentials --input=/tmp/credentials.json >/dev/null 2>&1
docker compose exec -T n8n rm -f /tmp/credentials.json
ok "Credentials imported"

log "Importing and publishing workflows"
./scripts/import-workflows.sh

cat <<EOF

$(ok "Stack ready")
  n8n         http://localhost:5678   ($ADMIN_EMAIL / see ADMIN_PASSWORD in .env)
  Mattermost  http://localhost:8065   (admin / same password) → team "Acme Inc"
  NocoDB      http://localhost:8080   ($ADMIN_EMAIL) → base "Sales CRM"
  Mailpit     http://localhost:8025
  PostgreSQL  localhost:${POSTGRES_HOST_PORT:-5433}  (db $POSTGRES_DB)
EOF
