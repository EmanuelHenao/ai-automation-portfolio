# AI Customer Support & Knowledge Base (RAG)

> A customer asks a question. The assistant searches the company's own help center, answers only from it — with sources — and hands the conversation to a human when it doesn't know or when money or account changes are involved. About 2 seconds per answer.

**Stack:** n8n · OpenAI (embeddings + GPT) · RAG · PostgreSQL + pgvector · REST APIs · Docker · nginx (web chat) · Mattermost (Slack-compatible)

![Workflow](screenshots/workflow.png)

| Answers grounded in the help center | Escalations reach the team with the reason |
|---|---|
| ![Chat](screenshots/chat.png) | ![Escalations](screenshots/support-escalations.png) |

## The business problem

Support teams answer the same questions every day — pricing, refunds, SSO, imports — while the answers already exist in their help center. Generic AI chatbots are risky: they invent prices, policies and features that don't exist, and they "promise" refunds nobody approved.

## What it automates

1. **Indexes** the help center: articles are split by section, embedded and stored in pgvector. Only new or changed articles are re-processed.
2. **Answers** customer questions using only the most relevant passages, in the customer's language, citing the articles used.
3. **Escalates** to a human whenever the answer isn't in the docs, the answer isn't grounded or confident, or the customer asks for an action on their account or money.
4. **Logs** every question with its outcome, sources and similarity score — a ready-made list of help-center gaps.

## Measured, not assumed

`scripts/eval.sh` runs a fixed evaluation set of 12 questions (8 answerable, 4 that must go to a human: missing integration, off-topic, double-charge refund request, prompt injection):

```
Outcome accuracy : 12/12  (answered vs escalated)
Source accuracy  : 8/8    (expected article cited)
Avg latency      : ~1.8s  (~790 tokens per answered question with gpt-4o-mini)
```

![Evaluation](screenshots/eval.png)

## Architecture

See [docs/architecture.md](docs/architecture.md) for the diagram, the four anti-hallucination layers and the ingestion design.

![Ingestion workflow](screenshots/workflow-ingestion.png)

```
Ingestion:  article → validate → hash check → chunk by section → embeddings → pgvector (atomic replace)
Question:   webhook → validate → embed → vector search → threshold → grounded LLM answer → guardrails
            → answer + sources  |  escalate to #support  → stored with outcome and sources
```

## Reliability & security

| Concern | How it's handled |
|---|---|
| Invented answers | Similarity threshold before the LLM, passages-only prompt, mandatory citations, guardrails in code |
| Risky requests | Refunds, billing disputes, deletions, security incidents and legal requests always go to a human |
| Prompt injection | Question treated as untrusted data; the model never decides alone — guardrails check citations and confidence |
| Unauthorized calls | `X-Webhook-Token` header → `401`; input validation → `400` |
| OpenAI down | 3 retries, then the customer receives a polite holding message and the question is escalated — never a raw error |
| Re-indexing cost | Content hash: unchanged articles are skipped |
| Half-updated index | Document + chunks replaced in a single SQL statement; on failure the previous version stays |
| Observability | `support_questions` (outcome, reason, sources, similarity) + `execution_log` (latency, tokens) + global error workflow |

## Run it locally

Requirements: Docker + Docker Compose, an OpenAI API key.

```bash
cp .env.example .env              # add your OPENAI_API_KEY
./scripts/bootstrap.sh
./03-ai-support-knowledge-base/scripts/demo.sh --reset   # indexes the help center and runs the evaluation
```

Open the chat at **http://localhost:8088** and ask anything. Each answer shows the help-center article and section it came from; click it to read the exact passage. Escalated questions show the ticket number.

The chat is a single static page (`chat/index.html`) served by nginx (`chat/nginx.conf.template`). nginx forwards questions to the `support-ask` webhook and adds the `X-Webhook-Token` header on the server, so the token never reaches the browser. It also limits each IP to 20 questions per minute and accepts only `POST` on `/api/ask`.

Or call the API directly:

```bash
curl -X POST http://localhost:5678/webhook/support-ask \
  -H "X-Webhook-Token: $WEBHOOK_TOKEN" -H "Content-Type: application/json" \
  -d '{"question": "Do you support SSO with Okta?", "customer_email": "ana@example.com"}'
```

```json
{
  "status": "answered",
  "ticket_id": 3,
  "answer": "Yes, we support single sign-on (SSO) with Okta, but it is available only on the Business plan.",
  "sources": [{ "title": "Security and privacy", "section": "Authentication", "source": "security-and-privacy.md" }]
}
```

Index or update an article (also used by `scripts/ingest-kb.sh`):

```bash
curl -X POST http://localhost:5678/webhook/kb-ingest -H "X-Webhook-Token: $WEBHOOK_TOKEN" \
  -H "Content-Type: application/json" -d '{"source": "faq.md", "title": "FAQ", "content": "# FAQ\n\n## ..."}'
# → 201 indexed | 201 updated | 200 unchanged
```

### Configuration

| Variable | Default | Meaning |
|---|---|---|
| `OPENAI_MODEL` | `gpt-4o-mini` | Model that writes the answers |
| `OPENAI_EMBEDDING_MODEL` | `text-embedding-3-small` | Embedding model (1536 dimensions) |
| `RAG_MIN_SIMILARITY` | `0.35` | Below this, a passage is ignored; no passage → escalate |
| `RAG_TOP_K` | `5` | Passages retrieved per question |

## Adapting it for a client

- **Knowledge source:** Notion, Confluence, Zendesk/Intercom help center, Google Drive or a website — anything that can be turned into text and sent to `/kb-ingest`, on a schedule or on change.
- **Channels:** the included web chat (`chat/`) embedded in the client's site, WhatsApp, email auto-replies, Slack, or draft replies inside the helpdesk for an agent to approve.
- **Escalation:** create a ticket in Zendesk, Freshdesk, HubSpot or Jira instead of (or in addition to) the chat alert.
- **Scale:** pgvector with HNSW handles hundreds of thousands of chunks; swap in Pinecone, Qdrant or Weaviate behind the same two nodes if needed.

## Portfolio checklist

| Question | Answer |
|---|---|
| What business problem does it solve? | Repetitive support questions take agent time, and generic AI bots invent answers. |
| What does it automate? | Indexing the help center, answering questions with sources, and routing everything else to a human with context. |
| Which tools does it integrate? | n8n, OpenAI embeddings and GPT, PostgreSQL + pgvector, a web chat (nginx), Mattermost/Slack, any text knowledge source. |
| What happens if something fails? | No relevant docs, ungrounded or low-confidence answers and account requests are escalated; AI outages return a polite holding message; failed re-indexing keeps the previous version. |
| What does the client get? | Instant, accurate answers for the common questions, fewer tickets for the team, and a measurable, auditable assistant that knows when not to answer. |
