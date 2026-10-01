-- Project 01: AI Lead Qualification & CRM Automation

CREATE TABLE IF NOT EXISTS leads (
    id              BIGSERIAL PRIMARY KEY,
    request_id      UUID        NOT NULL,
    email           TEXT        NOT NULL,
    full_name       TEXT        NOT NULL,
    company         TEXT,
    website         TEXT,
    phone           TEXT,
    message         TEXT        NOT NULL,
    budget          TEXT,
    source          TEXT        NOT NULL DEFAULT 'web_form',
    -- AI qualification
    score           SMALLINT    CHECK (score BETWEEN 0 AND 100),
    category        TEXT        CHECK (category IN ('hot', 'warm', 'cold', 'spam')),
    intent          TEXT,
    budget_signal   TEXT,
    urgency         TEXT,
    reasoning       TEXT,
    next_action     TEXT,
    -- routing
    route           TEXT        NOT NULL CHECK (route IN ('sales_alert', 'crm', 'nurture', 'discarded', 'manual_review')),
    llm_model       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_leads_email UNIQUE (email)
);
CREATE INDEX IF NOT EXISTS idx_leads_category ON leads (category, created_at DESC);
