#!/usr/bin/env bash
# Imports every workflow JSON in the repo into n8n, publishes it and restarts n8n
# so webhooks are registered. Run it after editing a workflow file.
set -euo pipefail
cd "$(dirname "$0")/.."

json() { python3 -c "import sys,json; d=json.load(sys.stdin); print($1)"; }

for wf in shared/workflows/*.json [0-9][0-9]-*/workflows/*.json; do
  [[ -f "$wf" ]] || continue
  docker compose exec -T n8n n8n import:workflow --input="/portfolio/$wf" >/dev/null 2>&1 \
    || { echo "✗ Import failed: $wf" >&2; exit 1; }
  docker compose exec -T n8n n8n publish:workflow --id="$(json "d['id']" < "$wf")" >/dev/null 2>&1 \
    || { echo "✗ Publish failed: $wf" >&2; exit 1; }
  echo "✓ $(json "d['name']" < "$wf")"
done

docker compose restart n8n >/dev/null 2>&1

# /healthz answers before production webhooks are registered: wait until every webhook path responds
paths=$(cat shared/workflows/*.json [0-9][0-9]-*/workflows/*.json 2>/dev/null | python3 -c "
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
  [[ "$(curl -s -o /dev/null -w '%{http_code}' http://localhost:5678/healthz)" == "200" && $ready == 1 ]] && exit 0
  sleep 2
done
echo "✗ n8n did not come back up with its webhooks registered" >&2; exit 1
