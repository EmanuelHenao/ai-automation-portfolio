-- Project 02: AI Document Processing & Data Extraction

CREATE TABLE IF NOT EXISTS invoices (
    id                BIGSERIAL PRIMARY KEY,
    request_id        UUID          NOT NULL,
    file_name         TEXT          NOT NULL,
    file_sha256       CHAR(64)      NOT NULL,
    extraction_method TEXT,
    -- extracted data
    is_invoice        BOOLEAN,
    vendor_name       TEXT,
    vendor_tax_id     TEXT,
    invoice_number    TEXT,
    invoice_date      DATE,
    due_date          DATE,
    currency          CHAR(3),
    subtotal          NUMERIC(14, 2),
    tax               NUMERIC(14, 2),
    total             NUMERIC(14, 2),
    -- validation
    status            TEXT          NOT NULL CHECK (status IN ('approved', 'needs_review')),
    issues            JSONB         NOT NULL DEFAULT '[]',
    raw_text          TEXT,
    llm_model         TEXT,
    created_at        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT uq_invoices_file UNIQUE (file_sha256)
);
CREATE INDEX IF NOT EXISTS idx_invoices_vendor_number ON invoices (lower(vendor_name), invoice_number);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices (status, created_at DESC);

CREATE TABLE IF NOT EXISTS invoice_items (
    id          BIGSERIAL PRIMARY KEY,
    invoice_id  BIGINT        NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
    line_no     SMALLINT      NOT NULL,
    description TEXT          NOT NULL,
    quantity    NUMERIC(12, 3),
    unit_price  NUMERIC(14, 2),
    amount      NUMERIC(14, 2)
);
CREATE INDEX IF NOT EXISTS idx_invoice_items_invoice ON invoice_items (invoice_id);
