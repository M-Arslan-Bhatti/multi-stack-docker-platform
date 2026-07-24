-- Runs automatically on first container start because it's mounted into
-- /docker-entrypoint-initdb.d/ of the official postgres image.

CREATE TABLE IF NOT EXISTS entries (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
