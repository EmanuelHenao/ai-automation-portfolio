-- Project 03: AI Customer Support & Knowledge Base (RAG with pgvector)

CREATE EXTENSION IF NOT EXISTS vector;

-- One row per source document (e.g. a help-center article)
CREATE TABLE IF NOT EXISTS kb_documents (
    id             BIGSERIAL PRIMARY KEY,
    source         TEXT        NOT NULL UNIQUE,   -- stable identifier, e.g. file name or URL
    title          TEXT        NOT NULL,
    content_sha256 CHAR(64)    NOT NULL,          -- unchanged documents are not re-embedded
    chunk_count    INTEGER     NOT NULL DEFAULT 0,
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Searchable pieces of each document with their embedding
CREATE TABLE IF NOT EXISTS kb_chunks (
    id          BIGSERIAL PRIMARY KEY,
    document_id BIGINT       NOT NULL REFERENCES kb_documents (id) ON DELETE CASCADE,
    chunk_index SMALLINT     NOT NULL,
    heading     TEXT,
    content     TEXT         NOT NULL,
    embedding   vector(1536) NOT NULL             -- OpenAI text-embedding-3-small
);
-- No unique (document_id, chunk_index): re-indexing deletes old chunks and inserts new ones in one statement
CREATE INDEX IF NOT EXISTS idx_kb_chunks_document ON kb_chunks (document_id);
CREATE INDEX IF NOT EXISTS idx_kb_chunks_embedding ON kb_chunks USING hnsw (embedding vector_cosine_ops);

-- Every question asked and what the assistant did with it
CREATE TABLE IF NOT EXISTS support_questions (
    id                BIGSERIAL PRIMARY KEY,
    request_id        UUID        NOT NULL,
    channel           TEXT        NOT NULL DEFAULT 'web_chat',
    customer_email    TEXT,
    question          TEXT        NOT NULL,
    status            TEXT        NOT NULL CHECK (status IN ('answered', 'escalated')),
    escalation_reason TEXT,
    answer            TEXT,
    confidence        TEXT,
    top_similarity    NUMERIC(5, 4),
    sources           JSONB       NOT NULL DEFAULT '[]',
    llm_model         TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_support_questions_status ON support_questions (status, created_at DESC);
