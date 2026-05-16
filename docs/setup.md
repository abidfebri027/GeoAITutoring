# Setup

Follow this path to run the recommended Telegram MVP with adaptive Socratic tutoring and RAG-based curriculum retrieval.

## 1. Telegram Bot

1. Open Telegram and message `@BotFather`.
2. Run `/newbot`.
3. Copy the bot token.
4. In n8n, create Telegram credentials using that token.

## 2. Supabase Database

1. Create a Supabase project.
2. Open the Supabase SQL editor.
3. Run `supabase/rag_setup.sql` for the recommended v3 workflow.
4. Do not run `supabase/schema.sql` in the same table namespace for the v3 workflow unless you intentionally adapt the table names. The older analytics schema also defines `student_profiles`, but with a different structure.
5. Confirm the `vector` extension is enabled.

The RAG schema uses `vector(1536)`, matching `text-embedding-3-small`. If you choose a different embedding model, update the vector dimension before inserting embeddings.

## 3. n8n Workflow

1. Import `n8n/workflows/geoai-enhanced-socratic-tutor-v3.workflow.json`.
2. Configure credentials:
   - Telegram Bot API
   - Supabase Postgres
   - OpenAI chat model credential
   - HTTP Header Auth credential for OpenAI embeddings
3. Check the SQL query expressions in the Postgres nodes, because n8n versions can differ slightly.
4. Activate the workflow.
5. Send a test message to the Telegram bot.

The recommended v3 workflow creates its own lightweight `student_profiles` table on first contact and uses `lesson_chunks` from `supabase/rag_setup.sql` for retrieval.

For the older full analytics workflow, use `supabase/schema.sql` and `supabase/seed_concepts.sql` in a separate database/schema or rename the overlapping `student_profiles` table first.

## 4. First Test Messages

```text
Why do earthquakes happen?
I do not understand.
Is tsunami caused by wind?
Can you just give me the answer?
Quiz me.
/progress
/hint
```

Expected behavior:

- asks a guiding question before giving a full answer
- gives hints when the student is stuck
- repairs misconceptions gently
- retrieves lesson context from `lesson_chunks`
- can show progress and force hints through Telegram commands
- moves toward assessment after stronger performance

## 5. RAG Content

The recommended v3 workflow expects RAG tables. To enable useful retrieval:

1. Run `supabase/rag_setup.sql`.
2. Prepare content using `rag/knowledge-base-guide.md`.
3. Generate embeddings into `lesson_chunks.embedding`.
4. Confirm `Search Lesson Chunks` returns rows for common questions.

For production document ingestion, use RAGFlow for complex PDFs, scanned materials, diagrams, tables, and citation quality.

## 6. Deployment Notes

- Store real secrets in n8n credentials or a secret manager.
- Do not commit `.env` files.
- Use a limited database user for n8n where possible.
- Add teacher/admin dashboards only after the core Telegram loop is stable.
