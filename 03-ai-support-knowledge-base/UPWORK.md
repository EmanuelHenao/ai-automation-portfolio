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

## Images to upload (in this order, with caption)
1. `screenshots/cover.png`
   Caption: AI support assistant (RAG) that answers only from your help center: n8n, OpenAI and PostgreSQL + pgvector.
2. `screenshots/chat.png`
   Caption: Real answers with cited sources, in English and Spanish; a refund request is escalated to a human.
3. `screenshots/workflow.png`
   Caption: The n8n support workflow: validation, semantic search, grounded AI answer, and code guardrails that decide answer or escalate.
4. `screenshots/eval.png`
   Caption: Automatic evaluation: 12/12 correct answer-or-escalate decisions, including off-topic questions and a prompt-injection attempt.
5. `screenshots/architecture.png`
   Caption: Architecture: help center ingestion into pgvector, plus the question → search → answer or escalate flow.
6. `screenshots/support-escalations.png`
   Caption: Escalations in the team channel with the customer's question, the reason and the closest article.

## Optional links
- GitHub: `https://github.com/EmanuelHenao/ai-automation-portfolio/tree/main/03-ai-support-knowledge-base`
- Demo video (Loom, 90 s): pricing question → Spanish question → refund request escalated → evaluation run
