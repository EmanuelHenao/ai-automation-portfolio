import io

from fastapi.testclient import TestClient
from PIL import Image, ImageDraw, ImageFont
from reportlab.pdfgen import canvas

from app.main import app

client = TestClient(app)


def make_pdf(text: str | None) -> bytes:
    buf = io.BytesIO()
    c = canvas.Canvas(buf)
    if text:
        c.drawString(72, 750, text)
    c.save()
    return buf.getvalue()


def make_scanned_pdf(text: str) -> bytes:
    """A PDF whose only content is a picture of text, like a scanner output."""
    from reportlab.lib.utils import ImageReader
    buf = io.BytesIO()
    c = canvas.Canvas(buf)
    c.drawImage(ImageReader(io.BytesIO(make_png(text))), 40, 600, width=520, height=100)
    c.save()
    return buf.getvalue()


def make_png(text: str) -> bytes:
    img = Image.new("L", (1600, 300), 255)
    font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 60)
    ImageDraw.Draw(img).text((40, 100), text, font=font, fill=0)
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return buf.getvalue()


def test_health():
    assert client.get("/health").json()["status"] == "ok"


def test_digital_pdf_uses_text_layer():
    pdf = make_pdf("Invoice INV-001 total due 1,250.00 USD from Acme Corp")
    res = client.post("/extract", files={"file": ("inv.pdf", pdf, "application/pdf")})
    body = res.json()
    assert res.status_code == 200
    assert body["method"] == "pdf_text"
    assert "INV-001" in body["text"]
    assert len(body["sha256"]) == 64


def test_image_goes_through_ocr():
    res = client.post("/extract", files={"file": ("scan.png", make_png("INVOICE 4821 TOTAL 990"), "image/png")})
    body = res.json()
    assert res.status_code == 200
    assert body["method"] == "image_ocr"
    assert "4821" in body["text"]


def test_scanned_pdf_falls_back_to_ocr():
    pdf = make_scanned_pdf("INVOICE 7310 TOTAL 455")
    res = client.post("/extract", files={"file": ("scan.pdf", pdf, "application/pdf")})
    body = res.json()
    assert res.status_code == 200
    assert body["method"] == "pdf_ocr"
    assert "7310" in body["text"]


def test_rejects_unsupported_type():
    res = client.post("/extract", files={"file": ("notes.txt", b"hello", "text/plain")})
    assert res.status_code == 415


def test_detects_type_from_content_not_extension():
    pdf = make_pdf("Invoice disguised with a wrong content type")
    res = client.post("/extract", files={"file": ("file.bin", pdf, "application/octet-stream")})
    assert res.status_code == 200
    assert res.json()["mime_type"] == "application/pdf"


def test_rejects_corrupted_pdf():
    res = client.post("/extract", files={"file": ("broken.pdf", b"%PDF-1.4 garbage", "application/pdf")})
    assert res.status_code == 422


def test_rejects_empty_file():
    res = client.post("/extract", files={"file": ("empty.pdf", b"", "application/pdf")})
    assert res.status_code == 400
