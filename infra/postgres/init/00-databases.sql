-- Separate databases for n8n internals and Mattermost.
-- Business data for the portfolio projects lives in the default database (POSTGRES_DB).
CREATE DATABASE n8n;
CREATE DATABASE mattermost;
CREATE DATABASE nocodb;
