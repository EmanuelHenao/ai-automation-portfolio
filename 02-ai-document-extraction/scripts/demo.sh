#!/usr/bin/env bash
# Uploads every sample document to the workflow and shows what happened.
#   ./02-ai-document-extraction/scripts/demo.sh          run the demo
#   ./02-ai-document-extraction/scripts/demo.sh --reset  clear demo data first
set -euo pipefail
cd "$(dirname "$0")/../.."
set -a; . ./.env; set +a

URL=${INVOICE_WEBHOOK_URL:-http://localhost:5678/webhook/invoice-intake}
SAMPLES=02-ai-document-extraction/samples
psql() { docker compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" "$@"; }
title() { printf '\n\033[1;36m━━ %s\033[0m\n' "$*"; }

if [[ "${1:-}" == "--reset" ]]; then
  title "Resetting demo data"
  psql -qc "TRUNCATE invoices, invoice_items RESTART IDENTITY; DELETE FROM execution_log WHERE project = '02-document-extraction';"
  echo "done"
fi

upload() { # upload LABEL FILE [TOKEN]
  title "$1"
  curl -s -w '\n  → HTTP %{http_code}\n' -X POST "$URL" -H "X-Webhook-Token: ${3-$WEBHOOK_TOKEN}" -F "file=@$2" \
    | python3 -c '
import sys, json
raw = sys.stdin.read()
body, code = raw.rsplit("\n  → ", 1)
try:
    d = json.loads(body)
    inv = d.get("invoice") or {}
    summary = {k: d[k] for k in ("status", "invoice_id", "extraction_method") if k in d}
    if inv.get("vendor_name"):
        summary["invoice"] = "{} #{} {} {} ({} lines)".format(inv["vendor_name"], inv["invoice_number"], inv["currency"], inv["total"], len(inv["line_items"]))
    print(json.dumps(summary))
    for key in ("issues", "errors"):
        for msg in d.get(key) or []:
            print("   •", msg)
    if d.get("status") == "duplicate":
        print("  ", d.get("message"))
except ValueError:
    print(body)
print("  →", code.strip())'
}

upload "Request without a valid token (expect 401)" "$SAMPLES/01-clean-invoice.pdf" "wrong-token"
upload "Unsupported file type (expect 415)" "$SAMPLES/06-unsupported.txt"
upload "Clean digital PDF (expect approved)" "$SAMPLES/01-clean-invoice.pdf"
upload "Scanned image, OCR (expect approved)" "$SAMPLES/02-scanned-invoice.png"
upload "Totals that don't add up (expect needs_review)" "$SAMPLES/03-wrong-totals.pdf"
upload "Same invoice number, different file (expect needs_review: duplicate payment)" "$SAMPLES/04-same-number-new-file.pdf"
upload "Not an invoice (expect needs_review)" "$SAMPLES/05-not-an-invoice.pdf"
upload "Exact same file again (expect duplicate, no AI cost)" "$SAMPLES/01-clean-invoice.pdf"

sleep 2
title "Invoices in PostgreSQL"
psql -c "SELECT i.id, i.vendor_name, i.invoice_number, i.total, i.status, i.extraction_method AS method, count(it.id) AS lines
         FROM invoices i LEFT JOIN invoice_items it ON it.invoice_id = i.id GROUP BY i.id ORDER BY i.id;"
title "Execution log"
psql -c "SELECT status, left(detail, 70) AS detail, latency_ms, prompt_tokens + completion_tokens AS tokens
         FROM execution_log WHERE project = '02-document-extraction' ORDER BY id;"

cat <<EOF

Check the results visually:
  Finance channel (Mattermost)  http://localhost:8065/acme/channels/invoices
  Executions (n8n)              http://localhost:5678/workflow/invoiceExtract01/executions
EOF
