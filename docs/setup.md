# Setup

Follow this path to get the Telegram MVP running first, then add retrieval and analytics.

## 1. Telegram Bot

1. Open Telegram and message `@BotFather`.
2. Run `/newbot`.
3. Copy the bot token.
4. In n8n, create Telegram credentials using that token.

## 2. Supabase Database

1. Create a Supabase project.
2. Open the Supabase SQL editor.
3. Run `supabase/schema.sql`.
4. Run `supabase/seed_concepts.sql`.
5. Confirm the `vector` extension is enabled.

The schema uses `vector(1536)`, matching `text-embedding-3-small`. If you choose a different embedding model, update the vector dimension before inserting embeddings.

## 3. n8n Workflow

1. Import `n8n/workflows/telegram-socratic-tutor.workflow.json`.
2. Configure credentials:
   - Telegram Bot API
   - Supabase Postgres
   - LLM provider API key
3. Check the SQL query parameter expressions in each Postgres node, because n8n versions can differ slightly.
4. Activate the workflow.
5. Send a test message to the Telegram bot.

## 4. First Test Messages

```text
Why do earthquakes happen?
I do not understand.
Is tsunami caused by wind?
Can you just give me the answer?
Quiz me.
```

Expected behavior:

- asks a guiding question before giving a full answer
- gives hints when the student is stuck
- repairs misconceptions gently
- moves toward assessment after stronger performance

## 5. Add RAG

The starter workflow can run without RAG. To enable retrieval:

1. Prepare content using `rag/knowledge-base-guide.md`.
2. Insert starter chunks from `rag/sample-curriculum-chunks.sql`.
3. Generate embeddings into `knowledge_chunks.embedding`.
4. Add the nodes described in `n8n/rag-query-addon.md`.

For production document ingestion, use RAGFlow for complex PDFs, scanned materials, diagrams, tables, and citation quality.

## 6. Deployment Notes

- Store real secrets in n8n credentials or a secret manager.
- Do not commit `.env` files.
- Use a limited database user for n8n where possible.
- Add teacher/admin dashboards only after the core Telegram loop is stable.

