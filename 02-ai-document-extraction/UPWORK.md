# Upwork portfolio entry — Project 02

## Title (max ~70 chars)
AI Invoice Data Extraction with OCR, n8n, Python and OpenAI

## Your role
AI Automation Developer

## Project description

*Portfolio project built around a common real-world scenario; fully working and documented on GitHub.*

**Problem:** Accounts-payable teams type invoices by hand — vendor, dates, every line item and total — into spreadsheets or their ERP. It takes hours every week, and the expensive mistakes (totals that don't add up, invoices paid twice) are easy to miss.

**Solution:** I built an automated invoice processing pipeline. Documents arrive as PDFs or photos/scans; a Python (FastAPI) microservice reads them using the PDF text layer or OCR; an AI model extracts vendor, tax ID, invoice number, dates, currency, totals and all line items into a strict structure; and an n8n workflow validates everything before saving it:

- Checks every line (quantity × price), the subtotal, tax and total
- Detects the same file uploaded twice, and the same invoice number arriving in a different file (possible double payment)
- Flags unreadable scans and documents that are not invoices
- Saves invoice + line items to PostgreSQL and notifies finance with the exact reasons when human review is needed

**Built for reliability:** secured endpoint, file type detection by content, size/page limits, AI that only transcribes (the math is verified in code, never "fixed" by the AI), automatic retries, no document is ever lost when a service is down, transactional storage, unit tests, and a full log with processing time and AI cost per document.

**Result:** Invoices are captured in about 3 seconds instead of minutes, clean ones go straight through, and the finance team only reviews the few that have a real problem — with the reason written out.

Easily connected to Gmail/Outlook attachments, Google Drive, QuickBooks, Xero, an ERP or Google Sheets, and adaptable to receipts, purchase orders or delivery notes.

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
