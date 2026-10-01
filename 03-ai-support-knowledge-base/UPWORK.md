# Upwork portfolio entry — Project 03

## Title (max ~70 chars)
AI Support Assistant with RAG: Answers Only From Your Docs (n8n + OpenAI)

## Your role
AI Automation Developer

## Project description

*Portfolio project built around a common real-world scenario; fully working and documented on GitHub.*

**Problem:** Support teams answer the same questions every day even though the answers already live in their help center. Generic AI chatbots aren't a safe fix: they invent prices, policies and features, and can promise refunds nobody approved.

**Solution:** I built a retrieval-augmented (RAG) support assistant with n8n, OpenAI and PostgreSQL + pgvector:

- The help center is split into sections, embedded and indexed; only new or changed articles are re-processed
- Each question is matched with the most relevant passages, and the AI answers **only** from them, in the customer's language, citing its sources
- If nothing relevant is found, the answer isn't backed by a cited passage, confidence is low, or the customer asks for a refund, a billing correction or an account change, the question goes to a human with the reason and the closest article
- Every question is stored with its outcome and sources, which shows exactly where the help center has gaps

**Measured, not assumed:** an automatic evaluation set of 12 questions (including off-topic, unsupported features, a double-charge refund request and a prompt-injection attempt) scores 12/12 on answer-or-escalate decisions and 8/8 on citing the right article, at about 2 seconds per answer.

**Built for reliability:** secured endpoints, input validation, four independent layers against made-up answers, polite fallback if the AI service is down, atomic re-indexing, full logging of latency and AI cost, and alerts to the team channel.

**Result:** Customers get instant, accurate answers to common questions, the team only handles what really needs a person — with context — and the business keeps control over what the AI is allowed to say.

Works with Notion, Confluence, Zendesk or Intercom help centers, Google Drive or websites, and can answer through a chat widget, WhatsApp, email or Slack.

## Skills / deliverables (max 5)
1. Retrieval Augmented Generation
2. AI Chatbot
3. n8n
4. OpenAI API
5. PostgreSQL

## Images to upload (in this order)
1. `screenshots/cover.png` — cover with the one-line pitch and the stack
2. `screenshots/chat.png` — real answers with sources, and an escalation
3. `screenshots/workflow.png` — n8n support workflow with the 4 colored sections
4. `screenshots/eval.png` — evaluation results (12/12)
5. `screenshots/architecture.png` — architecture diagram
6. `screenshots/support-escalations.png` — extra: escalations in the team channel

## Optional links
- GitHub: `https://github.com/EmanuelHenao/ai-automation-portfolio/tree/main/03-ai-support-knowledge-base`
- Demo video (Loom, 90 s): pricing question → Spanish question → refund request escalated → evaluation run
