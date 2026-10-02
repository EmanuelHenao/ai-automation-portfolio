# Upwork portfolio entry — Project 03

## Title (max ~70 chars)
AI Support Assistant with RAG: Answers Only From Your Docs (n8n + OpenAI)

## Your role
AI Automation Developer

## Project description (max 600 chars)
Problem: support teams answer the same questions daily, and generic chatbots invent prices, policies and refunds.

Solution: a RAG assistant (n8n, OpenAI, pgvector) that answers only from the help center, in the customer's language, citing sources. Off-topic or low-confidence questions, and refund, billing or account requests, go to a human with the reason and closest article.

Measured: 12/12 correct answer-or-escalate decisions on an eval set (including a prompt-injection attempt), ~2 s per answer.

Result: instant, accurate answers; the team only handles what needs a person.

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
