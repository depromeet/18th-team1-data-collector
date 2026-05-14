# Depromeet 18th team 1 n8n pipeline

This repository contains an `n8n` pipeline for collecting novel books from the Aladin Open API, extracting quotes in later steps, classifying quote emotions with an LLM, and storing quote embeddings in PostgreSQL with `pgvector`.

## Database

Run `db/init.sql` against an admin database such as `postgres` before importing the workflows.

```bash
psql -h <host> -p <port> -U <user> -d postgres -f db/init.sql
```

The script creates the `depromeet-team1` database when it does not exist, connects to it, and then creates the tables.

Main tables:
- `books`: book-level entity with Aladin metadata
- `quotes`: quote-level entity linked to `books`

Legacy tables from the previous schema are renamed to `books_legacy` and `book_quote_staging_legacy` when `db/init.sql` detects the old layout.

## Workflow order

1. `n8n/workflow-aladin-books.json`
   - Collects validated book metadata from the Aladin Open API
   - Upserts into `books`
   - Saves ISBN, publisher, publication date, Aladin link, and cover URL

2. `n8n/workflow-quote-extraction.json`
   - Reads `books.quote_extract_status = false`
   - Fetches book text from `BOOK_TEXT_API_URL`
   - Uses Groq to extract 3 exact sentences per book
   - Rejects extracted sentences that are not found in the fetched source text
   - Inserts extracted quotes into `quotes`

3. `n8n/workflow-quote-review.json`
   - Reads quotes attached to Aladin-validated books
   - Uses Groq to check hallucination risk, malformed text, and sentence quality
   - Marks quotes as `validated`, `needs_review`, or `retry_wait`

4. `n8n/workflow-emotion.json`
   - Reads quote-validated rows
   - Uses Groq to classify `emotion_valence`, `situation_tags`, `purpose_tags`, and `emotion_candidates`
   - Saves tags into `quotes`

5. `n8n/workflow-embedding.json`
   - Reads emotion-validated quotes
   - Calls the local embedding API
   - Stores `vector(768)` embeddings in `quotes.embedding`

## Required services

- PostgreSQL with `pgvector`
- Aladin Open API TTB key
  - Replace `YOUR_ALADIN_TTB_KEY` in `n8n/workflow-aladin-books.json`
- Groq API key
  - Set `GROQ_API_KEY` in the n8n runtime environment, or replace `YOUR_GROQ_API_KEY` in the code nodes
- Book text API
  - Default: `http://host.docker.internal:8001/book-text`
  - Override with `BOOK_TEXT_API_URL` if needed
  - Receives `POST` JSON: `{ "id": 1, "title": "...", "author": "..." }`
  - Returns text in one of: `text`, `book_text`, `content`, `body`, or `data`
- Local embedding API
  - Default: `http://host.docker.internal:8002/embedding`
  - Override with `EMBEDDING_API_URL` if needed

## Local validation

```bash
npm test
```

This validates n8n workflow JSON files with `jq` and compiles the Python FastAPI entrypoints.

## Status model

### `books.aladin_status`
- `staged`: waiting for Aladin collection
- `validated`: collected from Aladin Open API
- `needs_review`: not confidently matched or missing required metadata
- `retry_wait`: temporary failure, retry after `next_retry_at`

### `quotes.quote_check_status`
- `staged`: waiting for LLM quote review
- `validated`: quote passed the review step
- `needs_review`: quote failed validation or response parsing
- `retry_wait`: temporary LLM/API failure, retry after `quote_check_next_retry_at`

### `quotes.emotion_status`
- `staged`: waiting for emotion classification
- `validated`: tags saved successfully
- `needs_review`: invalid or incomplete LLM tag output
- `retry_wait`: temporary LLM/API failure, retry after `emotion_next_retry_at`

### `quotes.embedding_status`
- `staged`: waiting for embedding
- `validated`: embedding saved successfully
- `needs_review`: malformed embedding response
- `retry_wait`: temporary API failure, retry after `embedding_next_retry_at`

## Notes

- The pipeline now assumes a `Book(1) -> Quote(N)` data model.
- Duplicate prevention is applied at `quotes(book_id, content_hash)`.
- Aladin book collection removes the separate Kyobo validation requirement.
- Quote extraction expects a book text service; metadata alone is not enough to produce exact sentences.
- Both LLM workflows process one row at a time to reduce free-tier `429` issues.
- The default emotion taxonomy is embedded in `n8n/workflow-emotion.json` and can be adjusted there.
