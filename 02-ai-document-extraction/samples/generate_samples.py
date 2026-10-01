"""Generates the fictional sample documents used by the demo.

Run inside the extractor image (it has reportlab and Pillow):
  docker compose run --rm -v ./02-ai-document-extraction/samples:/samples extractor \
    python /samples/generate_samples.py /samples
"""
import io
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont
from reportlab.lib import colors
from reportlab.lib.pagesizes import LETTER
from reportlab.lib.units import inch
from reportlab.pdfgen import canvas

OUT = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
BUYER = ["Northwind Automation LLC", "742 Evergreen Terrace, Suite 200", "Austin, TX 78701"]


def money(value: float) -> str:
    return f"${value:,.2f}"


def invoice_pdf(path, vendor, address, tax_id, number, date, due, items, tax_rate, total_override=None, note=None):
    c = canvas.Canvas(str(path), pagesize=LETTER)
    w, h = LETTER
    c.setFillColor(colors.HexColor("#1f2937"))
    c.setFont("Helvetica-Bold", 20)
    c.drawString(inch, h - inch, vendor)
    c.setFont("Helvetica", 10)
    for i, line in enumerate(address + [f"Tax ID: {tax_id}"]):
        c.drawString(inch, h - inch - 16 - i * 13, line)

    c.setFont("Helvetica-Bold", 26)
    c.drawRightString(w - inch, h - inch, "INVOICE")
    c.setFont("Helvetica", 10)
    for i, (k, v) in enumerate([("Invoice #", number), ("Invoice date", date), ("Due date", due)]):
        c.drawRightString(w - inch - 90, h - inch - 20 - i * 14, k)
        c.drawRightString(w - inch, h - inch - 20 - i * 14, v)

    c.setFont("Helvetica-Bold", 10)
    c.drawString(inch, h - 2.3 * inch, "Bill to")
    c.setFont("Helvetica", 10)
    for i, line in enumerate(BUYER):
        c.drawString(inch, h - 2.3 * inch - 14 - i * 13, line)

    y = h - 3.4 * inch
    c.setFillColor(colors.HexColor("#e5e7eb"))
    c.rect(inch, y - 6, w - 2 * inch, 20, fill=1, stroke=0)
    c.setFillColor(colors.black)
    c.setFont("Helvetica-Bold", 10)
    cols = [inch + 6, w - 3.6 * inch, w - 2.5 * inch, w - inch - 6]
    c.drawString(cols[0], y, "Description")
    c.drawRightString(cols[1], y, "Qty")
    c.drawRightString(cols[2], y, "Unit price")
    c.drawRightString(cols[3], y, "Amount")
    c.setFont("Helvetica", 10)
    subtotal = 0.0
    for desc, qty, price in items:
        y -= 22
        amount = round(qty * price, 2)
        subtotal += amount
        c.drawString(cols[0], y, desc)
        c.drawRightString(cols[1], y, f"{qty:g}")
        c.drawRightString(cols[2], y, money(price))
        c.drawRightString(cols[3], y, money(amount))

    tax = round(subtotal * tax_rate, 2)
    total = total_override if total_override is not None else round(subtotal + tax, 2)
    y -= 36
    for label, value, bold in [("Subtotal", subtotal, False), (f"Sales tax ({tax_rate:.0%})", tax, False), ("Total due (USD)", total, True)]:
        c.setFont("Helvetica-Bold" if bold else "Helvetica", 11 if bold else 10)
        c.drawRightString(cols[2], y, label)
        c.drawRightString(cols[3], y, money(value))
        y -= 18

    c.setFont("Helvetica", 9)
    c.setFillColor(colors.HexColor("#6b7280"))
    c.drawString(inch, inch, note or "Payment terms: Net 30. Bank transfer to account ending 4421. Thank you for your business!")
    c.save()


def scanned_invoice_png(path):
    """Draws an invoice as a phone/scanner photo: grey paper, slight rotation, noise and blur."""
    W, H = 1700, 2200
    img = Image.new("L", (W, H), 245)
    d = ImageDraw.Draw(img)
    font = lambda size: ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", size)
    bold = lambda size: ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)

    d.text((120, 120), "Andes Cloud Hosting S.A.S.", font=bold(52), fill=20)
    for i, line in enumerate(["Carrera 43A #1-50, Medellin, Colombia", "NIT: 901.234.567-8", "billing@andescloud.example"]):
        d.text((120, 200 + i * 42), line, font=font(30), fill=40)
    d.text((1150, 120), "INVOICE", font=bold(60), fill=20)
    for i, (k, v) in enumerate([("Invoice #", "AC-88213"), ("Date", "2026-09-05"), ("Due", "2026-10-05")]):
        d.text((1100, 210 + i * 42), f"{k}: {v}", font=font(30), fill=40)

    d.text((120, 420), "Bill to: " + BUYER[0], font=font(30), fill=40)
    y = 560
    d.rectangle((110, y - 10, W - 110, y + 45), fill=215)
    for x, t in [(130, "Description"), (980, "Qty"), (1160, "Unit price"), (1420, "Amount")]:
        d.text((x, y), t, font=bold(30), fill=20)
    items = [("Managed Kubernetes cluster (Sep)", 1, 420.00), ("Block storage 500 GB", 2, 45.00),
             ("Daily backups", 1, 60.00), ("Premium support hours", 3, 80.00)]
    subtotal = 0
    for desc, qty, price in items:
        y += 75
        amount = qty * price
        subtotal += amount
        d.text((130, y), desc, font=font(30), fill=30)
        d.text((990, y), str(qty), font=font(30), fill=30)
        d.text((1160, y), f"${price:,.2f}", font=font(30), fill=30)
        d.text((1420, y), f"${amount:,.2f}", font=font(30), fill=30)
    tax = round(subtotal * 0.19, 2)
    y += 130
    for label, value in [("Subtotal", subtotal), ("VAT (19%)", tax), ("TOTAL USD", subtotal + tax)]:
        d.text((1050, y), label, font=bold(32) if "TOTAL" in label else font(30), fill=20)
        d.text((1420, y), f"${value:,.2f}", font=bold(32) if "TOTAL" in label else font(30), fill=20)
        y += 55

    random.seed(7)
    noise = Image.effect_noise((W, H), 18).point(lambda p: p // 6)
    img = Image.blend(img, noise.convert("L"), 0.08)
    img = img.rotate(-1.2, expand=True, fillcolor=200).filter(ImageFilter.GaussianBlur(0.8))
    img.save(path, "PNG")


def letter_pdf(path):
    c = canvas.Canvas(str(path), pagesize=LETTER)
    w, h = LETTER
    c.setFont("Helvetica-Bold", 16)
    c.drawString(inch, h - inch, "Team offsite — lunch menu")
    c.setFont("Helvetica", 11)
    for i, line in enumerate(["Friday, October 9", "", "Starters: tomato soup, green salad",
                              "Mains: grilled chicken, vegetable lasagna", "Dessert: brownies",
                              "", "Please confirm dietary restrictions with HR before Wednesday."]):
        c.drawString(inch, h - 1.5 * inch - i * 16, line)
    c.save()


OUT.mkdir(parents=True, exist_ok=True)
office_items = [("Ergonomic office chair", 4, 289.00), ("Standing desk 60in", 2, 549.00),
                ("Monitor arm (dual)", 4, 119.50), ("Printer paper A4 (box of 10)", 3, 42.75)]
invoice_pdf(OUT / "01-clean-invoice.pdf", "Brightline Office Supplies",
            ["1200 Market St, Floor 3", "San Francisco, CA 94103"], "94-3217788",
            "INV-2026-0142", "2026-09-12", "2026-10-12", office_items, 0.0825)
scanned_invoice_png(OUT / "02-scanned-invoice.png")
invoice_pdf(OUT / "03-wrong-totals.pdf", "QuickPrint Studio", ["88 Broadway", "New York, NY 10012"], "13-5550192",
            "QP-5531", "2026-09-20", "2026-10-20",
            [("Business cards (500 units)", 2, 65.00), ("Roll-up banner 85x200", 1, 180.00), ("Flyers A5 (1,000)", 1, 140.00)],
            0.08875, total_override=612.40)
invoice_pdf(OUT / "04-same-number-new-file.pdf", "Brightline Office Supplies",
            ["1200 Market St, Floor 3", "San Francisco, CA 94103"], "94-3217788",
            "INV-2026-0142", "2026-09-12", "2026-10-12", office_items, 0.0825,
            note="REISSUED COPY - Payment terms: Net 30. Bank transfer to account ending 4421.")
letter_pdf(OUT / "05-not-an-invoice.pdf")
(OUT / "06-unsupported.txt").write_text("This is a plain text file, not a PDF or image.\n")
print("samples written to", OUT)
