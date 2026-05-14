\set target_database 'depromeet-team1'

SELECT 'CREATE DATABASE "' || :'target_database' || '"'
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = :'target_database'
)\gexec

\connect :target_database

CREATE EXTENSION IF NOT EXISTS vector;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'books'
          AND column_name = 'quote'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'books'
          AND column_name = 'aladin_status'
    ) THEN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = 'books_legacy'
        ) THEN
            RAISE EXCEPTION 'books_legacy already exists while books still matches the legacy schema. Clean up or rename the current books table before running init.sql again.';
        ELSE
            ALTER TABLE books RENAME TO books_legacy;
        END IF;
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = 'book_quote_staging'
    ) THEN
        IF EXISTS (
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name = 'book_quote_staging_legacy'
        ) THEN
            RAISE EXCEPTION 'book_quote_staging_legacy already exists while book_quote_staging still matches the legacy schema. Clean up or rename the current staging table before running init.sql again.';
        ELSE
            ALTER TABLE book_quote_staging RENAME TO book_quote_staging_legacy;
        END IF;
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS books (
    id BIGSERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    normalized_title TEXT NOT NULL,
    normalized_author TEXT NOT NULL,
    category TEXT,
    isbn13 VARCHAR(20),
    publisher TEXT,
    published_at DATE,
    aladin_status VARCHAR(30) NOT NULL DEFAULT 'staged',
    aladin_item_id BIGINT,
    aladin_link TEXT,
    aladin_cover_url TEXT,
    aladin_category_name TEXT,
    cover_image_url TEXT,
    retry_count INTEGER NOT NULL DEFAULT 0,
    next_retry_at TIMESTAMP NOT NULL DEFAULT NOW(),
    error_reason TEXT,
    quote_extract_status BOOLEAN NOT NULL DEFAULT FALSE,
    quote_extract_retry_count INTEGER NOT NULL DEFAULT 0,
    quote_extract_next_retry_at TIMESTAMP NOT NULL DEFAULT NOW(),
    quote_extract_error_reason TEXT,
    quote_extracted_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    validated_at TIMESTAMP,
    UNIQUE(normalized_title, normalized_author)
);

ALTER TABLE books ADD COLUMN IF NOT EXISTS isbn13 VARCHAR(20);
ALTER TABLE books ADD COLUMN IF NOT EXISTS publisher TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS published_at DATE;
ALTER TABLE books ADD COLUMN IF NOT EXISTS aladin_status VARCHAR(30) NOT NULL DEFAULT 'staged';
ALTER TABLE books ADD COLUMN IF NOT EXISTS aladin_item_id BIGINT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS aladin_link TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS aladin_cover_url TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS aladin_category_name TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS cover_image_url TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS quote_extract_status BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE books ADD COLUMN IF NOT EXISTS quote_extract_retry_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE books ADD COLUMN IF NOT EXISTS quote_extract_next_retry_at TIMESTAMP NOT NULL DEFAULT NOW();
ALTER TABLE books ADD COLUMN IF NOT EXISTS quote_extract_error_reason TEXT;
ALTER TABLE books ADD COLUMN IF NOT EXISTS quote_extracted_at TIMESTAMP;

ALTER TABLE books
    ALTER COLUMN title TYPE TEXT,
    ALTER COLUMN author TYPE TEXT,
    ALTER COLUMN normalized_title TYPE TEXT,
    ALTER COLUMN normalized_author TYPE TEXT,
    ALTER COLUMN category TYPE TEXT,
    ALTER COLUMN publisher TYPE TEXT;

CREATE TABLE IF NOT EXISTS quotes (
    id BIGSERIAL PRIMARY KEY,
    book_id BIGINT NOT NULL REFERENCES books(id) ON DELETE CASCADE,
    quote_raw TEXT NOT NULL,
    normalized_quote TEXT NOT NULL,
    content_hash CHAR(32) NOT NULL,
    source_model VARCHAR(100),
    quote_check_status VARCHAR(30) NOT NULL DEFAULT 'staged',
    quote_check_retry_count INTEGER NOT NULL DEFAULT 0,
    quote_check_next_retry_at TIMESTAMP NOT NULL DEFAULT NOW(),
    quote_check_error_reason TEXT,
    quote_checked_at TIMESTAMP,
    emotion_status VARCHAR(30) NOT NULL DEFAULT 'staged',
    emotion_retry_count INTEGER NOT NULL DEFAULT 0,
    emotion_next_retry_at TIMESTAMP NOT NULL DEFAULT NOW(),
    emotion_error_reason TEXT,
    emotion_model VARCHAR(100),
    emotion_valence VARCHAR(20),
    emotion_candidates JSONB NOT NULL DEFAULT '[]'::JSONB,
    situation_tags TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    purpose_tags TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
    classified_at TIMESTAMP,
    embedding_status VARCHAR(30) NOT NULL DEFAULT 'staged',
    embedding_retry_count INTEGER NOT NULL DEFAULT 0,
    embedding_next_retry_at TIMESTAMP NOT NULL DEFAULT NOW(),
    embedding_error_reason TEXT,
    embedding vector(768),
    embedded_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(book_id, content_hash)
);

CREATE INDEX IF NOT EXISTS idx_books_category ON books (category);
CREATE INDEX IF NOT EXISTS idx_books_aladin_status ON books (aladin_status, created_at);
CREATE INDEX IF NOT EXISTS idx_books_quote_extract_queue ON books (quote_extract_status, quote_extract_next_retry_at);
CREATE INDEX IF NOT EXISTS idx_quotes_book_id ON quotes (book_id);
CREATE INDEX IF NOT EXISTS idx_quotes_quote_check_queue ON quotes (quote_check_status, quote_check_next_retry_at);
CREATE INDEX IF NOT EXISTS idx_quotes_emotion_queue ON quotes (emotion_status, emotion_next_retry_at);
CREATE INDEX IF NOT EXISTS idx_quotes_embedding_queue ON quotes (embedding_status, embedding_next_retry_at);
CREATE INDEX IF NOT EXISTS idx_quotes_embedding ON quotes USING hnsw (embedding vector_cosine_ops);
