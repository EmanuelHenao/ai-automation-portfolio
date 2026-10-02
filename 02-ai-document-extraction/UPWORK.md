# Upwork portfolio entry — Project 02

## Title (max ~70 chars)
AI Invoice Data Extraction with OCR, n8n, Python and OpenAI

## Your role
AI Automation Developer

## Project description (max 600 chars)
Problem: finance teams type invoices into spreadsheets by hand, and wrong totals or invoices paid twice slip through.

Solution: PDFs and scans go to a Python (FastAPI) OCR service; OpenAI extracts vendor, dates, totals and every line item into a strict schema; n8n verifies the math in code, catches duplicate files and repeated invoice numbers, flags unreadable or non-invoice documents, saves to PostgreSQL and alerts finance with the exact reason.

Reliable: retries, no document lost if a service fails, unit tests.

Result: invoices captured in ~3 seconds; people only review real problems.

## Skills / deliverables (max 5)
1. Data Extraction
2. n8n
3. OpenAI API
4. Python
5. OCR

## Images to upload (in this order)
1. `screenshots/cover.png` — cover with the one-line pitch and the stack
2. `screenshots/result.png` — scanned invoice next to the extracted JSON
3. `screenshots/workflow.png` — n8n workflow with the 4 colored sections
4. `screenshots/architecture.png` — architecture diagram
5. `screenshots/finance-alerts.png` — review alerts with reasons + processed invoices

## Optional links
- GitHub: `https://github.com/EmanuelHenao/ai-automation-portfolio/tree/main/02-ai-document-extraction`
- Demo video (Loom, 90 s): upload clean PDF → scanned photo → wrong totals → duplicate
