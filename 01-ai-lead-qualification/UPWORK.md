# Upwork portfolio entry — Project 01

## Title (max ~70 chars)
AI Lead Qualification & CRM Automation with n8n and OpenAI

## Your role
AI Automation Developer

## Project description (max 600 chars)
Problem: sales teams read every inbound lead by hand, spam mixes with real opportunities, and hot leads wait hours for a reply.

Solution: an n8n pipeline that validates each form submission, blocks duplicates and has OpenAI score it (0-100, intent, budget, urgency) against the ideal customer profile. Business rules route it: hot → instant chat + email alert and CRM "Contact now"; warm/cold → CRM stage; spam filtered; uncertain → human review.

Reliable: retries, AI-down fallback, error alerts, cost log.

Result: hot leads reach sales in seconds, with zero manual CRM entry.

## Skills / deliverables (max 5)
1. n8n
2. OpenAI API
3. CRM Automation
4. API Integration
5. PostgreSQL

## Images to upload (in this order)
1. `screenshots/cover.png` — cover with the one-line pitch and the stack
2. `screenshots/workflow.png` — full n8n workflow with the 4 colored sections
3. `screenshots/architecture.png` — architecture diagram
4. `screenshots/sales-alert.png` — hot lead alert with AI reasoning in the team chat
5. `screenshots/crm.png` — CRM with leads in different stages
6. `screenshots/email.png` / `screenshots/ops-alert.png` / `screenshots/executions.png` — extras (email to sales, failure alert, execution history)

## Optional links
- GitHub: `https://github.com/EmanuelHenao/ai-automation-portfolio/tree/main/01-ai-lead-qualification`
- Demo video (Loom, 90 s): form submit → alert → CRM → error handling
