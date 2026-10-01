-- Shared observability tables used by every project.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- One row per processed request: who, what, how long, how many tokens.
CREATE TABLE IF NOT EXISTS execution_log (
    id              BIGSERIAL PRIMARY KEY,
    request_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    project         TEXT        NOT NULL,
    workflow        TEXT        NOT NULL,
    idempotency_key TEXT,
    status          TEXT        NOT NULL CHECK (status IN ('success', 'rejected', 'duplicate', 'failed')),
    detail          TEXT,
    latency_ms      INTEGER,
    llm_model       TEXT,
    prompt_tokens   INTEGER,
    completion_tokens INTEGER,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_execution_log_project_created ON execution_log (project, created_at DESC);

-- Unhandled failures captured by the n8n Error Workflow.
CREATE TABLE IF NOT EXISTS automation_errors (
    id            BIGSERIAL PRIMARY KEY,
    workflow_id   TEXT,
    workflow_name TEXT,
    execution_id  TEXT,
    failed_node   TEXT,
    error_message TEXT,
    execution_url TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
