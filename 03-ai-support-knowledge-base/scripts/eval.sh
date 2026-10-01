#!/usr/bin/env bash
# Runs the evaluation set against the support assistant and reports accuracy:
#   - outcome: answered vs escalated, as expected
#   - source:  for answered questions, the expected article is among the cited sources
set -euo pipefail
cd "$(dirname "$0")/../.."
set -a; . ./.env; set +a

URL=${SUPPORT_URL:-http://localhost:5678/webhook/support-ask} python3 - <<'PY'
import json, os, time, urllib.request

url, token = os.environ["URL"], os.environ["WEBHOOK_TOKEN"]
cases = json.load(open("03-ai-support-knowledge-base/samples/eval-questions.json"))
ok_outcome = ok_source = answered_expected = 0
latencies = []
for i, case in enumerate(cases, 1):
    body = json.dumps({"question": case["question"], "customer_email": f"customer{i}@example.com"}).encode()
    req = urllib.request.Request(url, body, {"Content-Type": "application/json", "X-Webhook-Token": token})
    start = time.time()
    res = json.load(urllib.request.urlopen(req, timeout=90))
    latencies.append(time.time() - start)
    outcome_ok = res["status"] == case["expect"]
    sources = [s["source"] for s in res.get("sources", [])]
    source_ok = case["expect"] != "answered" or case.get("source") in sources
    ok_outcome += outcome_ok
    if case["expect"] == "answered":
        answered_expected += 1
        ok_source += source_ok
    mark = "✓" if outcome_ok and source_ok else "✗"
    print(f"{mark} [{res['status']:9}] {case['question']}")
    print(f"      {res['answer'][:220].replace(chr(10), ' ')}")
    if sources:
        print(f"      sources: {', '.join(sorted(set(sources)))}")
print()
print(f"Outcome accuracy : {ok_outcome}/{len(cases)}  (answered vs escalated)")
print(f"Source accuracy  : {ok_source}/{answered_expected}  (expected article cited)")
print(f"Avg latency      : {sum(latencies) / len(latencies):.1f}s")
PY
