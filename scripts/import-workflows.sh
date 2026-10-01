#!/usr/bin/env bash
# Imports every workflow JSON in the repo into n8n and publishes it.
# n8n is stopped during the import so it always starts with the latest published versions
# (importing while it runs can leave the previous version active until the next restart).
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a

json() { python3 -c "import sys,json; d=json.load(sys.stdin); print($1)"; }

files=()
for wf in shared/workflows/*.json [0-9][0-9]-*/workflows/*.json; do
  [[ -f "$wf" ]] && files+=("$wf")
done

# one shell script with every import + publish, run in a one-off n8n container
script="set -e"
for wf in "${files[@]}"; do
  script+="; n8n import:workflow --input=/portfolio/$wf >/dev/null 2>&1 || { echo 'Import failed: $wf' >&2; exit 1; }"
  script+="; n8n publish:workflow --id=$(json "d['id']" < "$wf") >/dev/null 2>&1 || { echo 'Publish failed: $wf' >&2; exit 1; }"
done

docker compose stop n8n >/dev/null 2>&1
docker compose run --rm --no-deps -T --entrypoint sh n8n -c "$script" 2> >(grep -v "Container " >&2)
for wf in "${files[@]}"; do echo "✓ $(json "d['name']" < "$wf")"; done
docker compose up -d n8n >/dev/null 2>&1

# /healthz answers before production webhooks are registered: wait until every webhook path responds
paths=$(cat "${files[@]}" | python3 -c "
import sys, json
dec = json.JSONDecoder(); s = sys.stdin.read(); i = 0
while i < len(s):
    while i < len(s) and s[i].isspace(): i += 1
    if i >= len(s): break
    wf, i = dec.raw_decode(s, i)
    for n in wf['nodes']:
        if n['type'] == 'n8n-nodes-base.webhook': print(n['parameters']['path'])")
for _ in $(seq 1 90); do
  ready=1
  for p in $paths; do
    [[ "$(curl -s -o /dev/null -w '%{http_code}' -X POST "http://localhost:5678/webhook/$p")" == "404" ]] && ready=0
  done
  # n8n serves the previously published version for a few seconds after start, until it syncs
  # workflow_published_version with the newly published one: wait for that too
  stale=$(docker compose exec -T postgres psql -U "$POSTGRES_USER" -d n8n -Atc \
    "SELECT count(*) FROM workflow_entity w JOIN workflow_published_version p ON p.\"workflowId\" = w.id
     WHERE w.active AND p.\"publishedVersionId\" <> w.\"activeVersionId\"" 2>/dev/null || echo 1)
  [[ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:5678/healthz)" == "200" && $ready == 1 && "$stale" == "0" ]] && exit 0
  sleep 2
done
echo "✗ n8n did not come back up with its webhooks registered" >&2; exit 1
