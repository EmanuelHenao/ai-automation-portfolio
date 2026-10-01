"""Document text extraction service.

Turns an uploaded PDF or image into plain text so an LLM can extract structured data from it.
- Digital PDFs: text layer via pdfplumber (fast, exact).
- Scanned PDFs (no text layer) and images: OCR via Tesseract.
"""
import hashlib
import io
import logging
import os
import time

import pdfplumber
import pypdfium2 as pdfium
import pytesseract
from fastapi import FastAPI, File, HTTPException, UploadFile
from PIL import Image, ImageOps
from pydantic import BaseModel

MAX_FILE_BYTES = int(os.getenv("MAX_FILE_MB", "10")) * 1024 * 1024
MAX_PAGES = int(os.getenv("MAX_PAGES", "10"))
OCR_LANG = os.getenv("OCR_LANG", "eng+spa")
# A PDF page with less text than this is treated as scanned and sent to OCR
MIN_TEXT_CHARS_PER_PAGE = 30

PDF_TYPES = {"application/pdf"}
IMAGE_TYPES = {"image/png", "image/jpeg", "image/tiff", "image/webp"}

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger("extractor")

app = FastAPI(title="Document Extractor", version="1.0.0")


class ExtractionResult(BaseModel):
    file_name: str
    mime_type: str
    size_bytes: int
    sha256: str
    method: str  # pdf_text | pdf_ocr | image_ocr
    pages: int
    chars: int
    duration_ms: int
    text: str


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "tesseract": str(pytesseract.get_tesseract_version())}


@app.post("/extract", response_model=ExtractionResult)
async def extract(file: UploadFile = File(...)) -> ExtractionResult:
    started = time.monotonic()
    data = await file.read(MAX_FILE_BYTES + 1)
    if not data:
        raise HTTPException(status_code=400, detail="Empty file")
    if len(data) > MAX_FILE_BYTES:
        raise HTTPException(status_code=413, detail=f"File larger than {MAX_FILE_BYTES // (1024 * 1024)} MB")

    mime = _detect_mime(data, file.content_type)
    try:
        if mime in PDF_TYPES:
            text, method, pages = _from_pdf(data)
        elif mime in IMAGE_TYPES:
            text, method, pages = _ocr_image(Image.open(io.BytesIO(data))), "image_ocr", 1
        else:
            raise HTTPException(status_code=415, detail=f"Unsupported file type: {mime}")
    except HTTPException:
        raise
    except Exception as exc:  # corrupted or password-protected files
        log.warning("extraction failed for %s: %s", file.filename, exc)
        raise HTTPException(status_code=422, detail=f"Could not read the document: {exc}") from exc

    text = _normalize(text)
    result = ExtractionResult(
        file_name=file.filename or "document",
        mime_type=mime,
        size_bytes=len(data),
        sha256=hashlib.sha256(data).hexdigest(),
        method=method,
        pages=pages,
        chars=len(text),
        duration_ms=int((time.monotonic() - started) * 1000),
        text=text,
    )
    log.info("extracted %s method=%s pages=%d chars=%d in %dms",
             result.file_name, method, pages, result.chars, result.duration_ms)
    return result


def _detect_mime(data: bytes, declared: str | None) -> str:
    """Trust the file signature over the declared content type."""
    if data.startswith(b"%PDF"):
        return "application/pdf"
    if data.startswith(b"\x89PNG"):
        return "image/png"
    if data.startswith(b"\xff\xd8"):
        return "image/jpeg"
    if data[:4] in (b"II*\x00", b"MM\x00*"):
        return "image/tiff"
    if data[:4] == b"RIFF" and data[8:12] == b"WEBP":
        return "image/webp"
    return declared or "application/octet-stream"


def _from_pdf(data: bytes) -> tuple[str, str, int]:
    with pdfplumber.open(io.BytesIO(data)) as pdf:
        pages = len(pdf.pages)
        if pages == 0:
            raise HTTPException(status_code=422, detail="PDF has no pages")
        if pages > MAX_PAGES:
            raise HTTPException(status_code=413, detail=f"PDF has {pages} pages, limit is {MAX_PAGES}")
        texts = [page.extract_text() or "" for page in pdf.pages]

    if all(len(t.strip()) >= MIN_TEXT_CHARS_PER_PAGE for t in texts):
        return "\n\n".join(texts), "pdf_text", pages

    # Scanned PDF: render every page and OCR it
    doc = pdfium.PdfDocument(data)
    ocr_texts = [_ocr_image(page.render(scale=300 / 72).to_pil()) for page in doc]
    return "\n\n".join(ocr_texts), "pdf_ocr", pages


def _ocr_image(image: Image.Image) -> str:
    image = ImageOps.exif_transpose(image).convert("L")
    if image.width < 1500:  # upscale small images, Tesseract works best around 300 DPI
        ratio = 1500 / image.width
        image = image.resize((1500, int(image.height * ratio)), Image.LANCZOS)
    return pytesseract.image_to_string(image, lang=OCR_LANG, config="--psm 6")


def _normalize(text: str) -> str:
    lines = [" ".join(line.split()) for line in text.splitlines()]
    return "\n".join(line for line in lines if line).strip()
