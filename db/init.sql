CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS books (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    author VARCHAR(200) NOT NULL,
    quote TEXT NOT NULL,
    category VARCHAR(100),
    emotion_labels TEXT[],
    embedding vector(768),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(title, author)
);

CREATE TABLE IF NOT EXISTS book_quote_staging (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    author VARCHAR(200) NOT NULL,
    quote TEXT NOT NULL,
    category VARCHAR(100),
    batch_index INTEGER,
    batch_size INTEGER,
    raw_emotions TEXT[],
    emotion_labels TEXT[],
    embedding vector(768),
    status VARCHAR(30) NOT NULL DEFAULT 'collected',
    needs_review BOOLEAN NOT NULL DEFAULT FALSE,
    retry_count INTEGER NOT NULL DEFAULT 0,
    error_reason TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    processed_at TIMESTAMP,
    UNIQUE(title, author)
);

CREATE INDEX IF NOT EXISTS idx_books_embedding ON books USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_books_category ON books (category);
CREATE INDEX IF NOT EXISTS idx_book_quote_staging_status ON book_quote_staging (status, created_at);
CREATE INDEX IF NOT EXISTS idx_book_quote_staging_category ON book_quote_staging (category);
