#!/usr/bin/env bash
# Sends every markdown article in knowledge-base/ to the ingestion workflow.
# Unchanged articles are skipped by the workflow (content hash), so it is safe to run it any time.
set -euo pipefail
cd "$(dirname "$0")/../.."
set -a; . ./.env; set +a

URL=${KB_INGEST_URL:-http://localhost:5678/webhook/kb-ingest}
for file in 03-ai-support-knowledge-base/knowledge-base/*.md; do
  python3 - "$file" <<'PY' | curl -s -X POST "$URL" -H "X-Webhook-Token: $WEBHOOK_TOKEN" \
      -H 'Content-Type: application/json' --data-binary @- -w '\n' \
    | python3 -c 'import sys, json; d = json.load(sys.stdin); print("  %-9s %-32s chunks=%s %s" % (d.get("status"), d.get("source") or "", d.get("chunks", "-"), "; ".join(d.get("errors") or [])))'
import json, pathlib, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
title = next((line[2:].strip() for line in text.splitlines() if line.startswith("# ")), path.stem)
print(json.dumps({"source": path.name, "title": title, "content": text}))
PY
done
