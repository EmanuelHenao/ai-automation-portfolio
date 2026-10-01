# Upwork portfolio entry — Project 01

## Title (max ~70 chars)
AI Lead Qualification & CRM Automation with n8n and OpenAI

## Your role
AI Automation Developer

## Project description

*Portfolio project built around a common real-world scenario; fully working and documented on GitHub.*

**Problem:** Service businesses receive dozens of inbound leads per week through their website forms. The sales team reads every message manually, spam and unqualified requests are mixed with real opportunities, and hot leads sometimes wait a day for a reply.

**Solution:** I built an automated lead qualification pipeline in n8n. Every form submission is validated, checked for duplicates and analyzed by an AI model against the company's ideal customer profile. The AI returns a structured score (0-100), intent, budget signal and urgency, and clear business rules decide what happens next:

- Hot leads → instant chat alert + email to sales + CRM record marked "Contact now"
- Warm and cold leads → CRM with the right stage for follow-up or nurturing
- Spam → filtered out automatically
- Anything uncertain → routed to a human for review

**Built for reliability:** token-secured webhook, input validation, duplicate protection, strict JSON output from the AI, automatic retries, a fallback that never loses a lead if the AI is down, central error logging with alerts, and a full execution log with response time and AI cost per lead.

**Result:** Hot leads reach a salesperson in seconds instead of hours, the CRM stays up to date without manual data entry, and the team only spends time on leads worth talking to.

The workflow can connect to any form (Webflow, WordPress, Typeform, Facebook Lead Ads) and any CRM or chat (HubSpot, Pipedrive, Airtable, Slack, Teams).

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
