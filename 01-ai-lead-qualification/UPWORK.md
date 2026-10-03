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

## Images to upload (in this order, with caption)
1. `screenshots/cover.png`
   Caption: AI lead qualification pipeline built with n8n, OpenAI, PostgreSQL and a CRM.
2. `screenshots/workflow.png`
   Caption: The n8n workflow: intake and validation, duplicate check, AI scoring, and routing by business rules.
3. `screenshots/architecture.png`
   Caption: Architecture: form → n8n → OpenAI → PostgreSQL, CRM, team chat and email, with central error handling.
4. `screenshots/sales-alert.png`
   Caption: Hot lead alert in the team chat with score, budget, urgency, the AI's reasoning and a suggested next step.
5. `screenshots/crm.png`
   Caption: Leads land in the CRM automatically with their score and the right stage: Contact now, Qualify or Nurture.
6. `screenshots/email.png`
   Caption: Email sent to the sales team for every hot lead.
7. `screenshots/ops-alert.png`
   Caption: Failure alert: when a step fails, the team gets the node, the error and a link to the failed execution.
8. `screenshots/executions.png`
   Caption: n8n execution history: each lead processed in about 2 seconds; the failed run is caught by the global error handler.

## Optional links
- GitHub: `https://github.com/EmanuelHenao/ai-automation-portfolio/tree/main/01-ai-lead-qualification`
- Demo video (Loom, 90 s): form submit → alert → CRM → error handling
