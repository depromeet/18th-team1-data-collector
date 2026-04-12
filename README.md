# Depromeet 18th team 1 n8n pipeline

This repository contains an `n8n` pipeline for collecting novel quotes, processing emotion labels and embeddings, and storing the results in PostgreSQL with `pgvector`.

## Workflows

- `n8n/workflow.json`
  - Collects quotes with Groq
  - Stores raw results in `book_quote_staging`
- `n8n/workflow-process.json`
  - Reads `collected` rows from staging
  - Runs local emotion analysis and embedding
  - Upserts into `books`
  - Marks rows as `done` or `review_pending`
- `n8n/workflow-review.json`
  - Reads `review_pending` rows
  - Re-checks emotion labels with Groq
  - Updates both `books` and staging

## Database

Run `db/init.sql` before using the workflows.

Main tables:
- `books`: final dataset
- `book_quote_staging`: intermediate processing state

## Required services

- PostgreSQL with `pgvector`
- Local emotion API at `http://host.docker.internal:8001/emotion`
- Local embedding API at `http://host.docker.internal:8002/embedding`
- Groq API key for:
  - `n8n/workflow.json`
  - `n8n/workflow-review.json`

## Recommended order

1. Import and run `n8n/workflow.json`
2. Import and run `n8n/workflow-process.json`
3. If needed, run `n8n/workflow-review.json`

## Staging status

- `collected`: quote collected, not processed yet
- `review_pending`: processed but emotion labels need Groq review
- `done`: fully processed

## Notes

- Quote collection uses small batches of 5 items to reduce truncation and rate-limit issues.
- Emotion review is only applied to uncertain cases.
- Each workflow includes a step that ensures `book_quote_staging` exists before execution.
