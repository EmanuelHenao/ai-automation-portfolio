# AI Automation Portfolio

Production-minded AI automations built with **n8n**, **OpenAI**, **PostgreSQL** and custom backend services.
Each project is a small, working MVP that solves one business problem end to end — with validation, error handling, retries, logging and documentation.

| # | Project | In 30 seconds | Stack |
|---|---|---|---|
| 01 | [AI Lead Qualification & CRM Automation](01-ai-lead-qualification/) | A form lead is validated, scored by AI, stored, added to the CRM and the sales team is alerted in seconds. | n8n · OpenAI · PostgreSQL · NocoDB · Mattermost/Slack · Email |
| 02 | [AI Document Processing & Data Extraction](02-ai-document-extraction/) | A PDF or scanned invoice is read (OCR), extracted with AI, math-checked and stored; wrong totals and duplicate payments go to human review. | n8n · Python/FastAPI · Tesseract OCR · OpenAI · PostgreSQL |
| 03 | [AI Customer Support & Knowledge Base (RAG)](03-ai-support-knowledge-base/) | Questions are answered only from the company's help center, with sources; anything unknown or risky escalates to a human. 12/12 on its evaluation set. | n8n · OpenAI · RAG · pgvector · PostgreSQL |

## Engineering standards in every project

- **Secured entry points** — token-authenticated webhooks, input validation with clear `4xx` errors.
- **Predictable AI** — structured JSON outputs validated in code; business decisions made by rules, not by the model.
- **Failure handling** — retries with backoff, fallbacks that never lose data, a global error workflow that logs and alerts with a link to the failed execution.
- **Observability** — every request logged with status, latency and token usage.
- **Reproducible** — one command brings up the whole stack with Docker Compose; no secrets in the repo.

## Run everything locally

```bash
cp .env.example .env        # add your OPENAI_API_KEY
./scripts/bootstrap.sh      # starts the stack and configures every service
```

| Service | URL | Purpose |
|---|---|---|
| n8n | http://localhost:5678 | Workflows |
| PostgreSQL + pgvector | localhost:5433 | Business data, logs, embeddings |
| NocoDB | http://localhost:8080 | Lightweight CRM (Airtable-like) |
| Mattermost | http://localhost:8065 | Team alerts (Slack-compatible webhooks) |
| Mailpit | http://localhost:8025 | Captures outgoing email |
| Extractor | http://localhost:8000/docs | Project 02 OCR microservice (FastAPI) |
| Support chat | http://localhost:8088 | Project 03 web chat (nginx proxy to the n8n webhook) |

All services are open source. In a client project, Mattermost is swapped for Slack/Teams and NocoDB for HubSpot/Pipedrive/Airtable without changing the workflow logic.

## Repository layout

```
shared/workflows/        global error handler used by every workflow
infra/postgres/init/     database schemas
scripts/                 bootstrap, workflow import, demo helpers
01-…/ 02-…/ 03-…/        one folder per project: workflows, samples, demo script, docs, screenshots
02-…/extractor/          Python/FastAPI OCR service with unit tests
03-…/chat/               support chat web UI (static page + nginx proxy)
```

---
Built by Emanuel Henao — Senior backend engineer (Java/Spring, Python, PostgreSQL, Kafka) focused on AI and business automation.
