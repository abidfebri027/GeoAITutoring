# GeoAITutoring

**GeoAITutoring** is a starter kit for a Telegram-based Socratic AI tutor that helps students learn geography and natural-disaster concepts through guided questioning instead of direct answer dumping.

The first learning domain is **natural disasters**: earthquakes, volcanoes, floods, tsunamis, landslides, climate hazards, mitigation, risk, vulnerability, exposure, and disaster case studies.

## About

GeoAITutoring is an AI-powered adaptive learning system for geography education. It uses Telegram as the student interface, n8n as the automation layer, Supabase for persistent learning memory, and retrieval-augmented generation to ground tutoring responses in disaster-geography learning materials.

Instead of acting like a normal chatbot, the system guides students with Socratic questions, hints, misconception repair, short explanations, and adaptive assessments. The goal is to help students understand why disasters happen, how risk can be reduced, and how geographic concepts connect to real-world disaster events.

## Why This Exists

Most AI chatbots answer a student's question immediately. This project is designed to behave more like a careful tutor:

- asks one guiding question at a time
- gives hints before explanations
- detects misconceptions
- adapts difficulty from student performance
- tracks concept mastery over time
- uses curriculum-based retrieval for factual grounding

## Architecture

```text
Telegram Student
  -> Telegram Bot
  -> n8n Tutor Workflow
  -> Supabase Postgres memory/profile/mastery
  -> Supabase Vector or RAGFlow knowledge base
  -> Socratic Tutor LLM
  -> Scoring + mastery update
  -> Telegram Reply
```

Read the full design in [`docs/architecture.md`](docs/architecture.md).

## Features

- Telegram-first student interface
- n8n workflow blueprint for the tutoring loop
- Supabase schema for profiles, chat memory, mastery, misconceptions, assessments, and RAG chunks
- Socratic tutor prompt template
- scoring evaluator prompt and mastery update formula
- starter geography disaster concept map
- optional vector retrieval add-on
- setup docs for moving from MVP to production

## Recommended MVP Stack

| Layer | Tool |
| --- | --- |
| Student UI | Telegram Bot |
| Workflow orchestration | n8n |
| Database | Supabase Postgres |
| Chat memory | Supabase tables |
| Vector search | Supabase Vector/pgvector |
| Complex document ingestion | Optional RAGFlow |
| LLM provider | OpenAI, Gemini, Anthropic, or compatible API |

## Tech Stack

| Category | Technology | Purpose |
| --- | --- | --- |
| Chat interface | Telegram Bot API | Student-facing tutor chat |
| Automation | n8n | Workflow orchestration, routing, scoring, and integrations |
| Database | Supabase Postgres | Student profiles, sessions, chat memory, mastery, and scoring history |
| Vector search | Supabase Vector / pgvector | Retrieval for curriculum-based geography content |
| RAG ingestion | RAGFlow, optional | Parsing complex PDFs, diagrams, scanned documents, and case-study materials |
| AI models | OpenAI / Gemini / Anthropic | Socratic tutor replies, scoring, retrieval query rewriting |
| Prompts | Markdown prompt templates | Tutor behavior, scoring rubric, and retrieval query generation |
| Workflow assets | n8n JSON workflow + Code nodes | Importable Telegram tutoring automation |
| Deployment | n8n Cloud or self-hosted, Supabase Cloud | MVP hosting and managed persistence |
| Analytics | Supabase SQL, Metabase, or dashboard app | Teacher/admin mastery and progress tracking |

## Project Structure

```text
.
|-- docs/
|   |-- architecture.md
|   |-- roadmap.md
|   `-- setup.md
|-- n8n/
|   |-- code/
|   |-- workflows/
|   `-- rag-query-addon.md
|-- prompts/
|-- rag/
|-- supabase/
|-- .env.example
`-- README.md
```

## Quick Start

1. Create a Telegram bot with `@BotFather`.
2. Create a Supabase project.
3. Run [`supabase/schema.sql`](supabase/schema.sql) in the Supabase SQL editor.
4. Run [`supabase/seed_concepts.sql`](supabase/seed_concepts.sql).
5. Import [`n8n/workflows/telegram-socratic-tutor.workflow.json`](n8n/workflows/telegram-socratic-tutor.workflow.json) into n8n.
6. Configure n8n credentials:
   - Telegram Bot API
   - Supabase Postgres
   - LLM provider API key
7. Test the bot in Telegram:

```text
Why do earthquakes happen?
```

Detailed setup steps are in [`docs/setup.md`](docs/setup.md).

## Important Tutor Rule

The LLM should not freely decide when to reveal the final answer. n8n computes an `allowed_action`, and the tutor prompt must obey it.

Example policy:

```text
Low mastery -> ask a guiding question
Student stuck -> give a hint
Multiple failed attempts -> give a micro-explanation
Misconception detected -> repair the misconception
High mastery -> move to assessment
```

## RAG Notes

The starter workflow can run without retrieval first. When you are ready to add curriculum grounding:

1. Prepare learning chunks using [`rag/knowledge-base-guide.md`](rag/knowledge-base-guide.md).
2. Insert starter examples from [`rag/sample-curriculum-chunks.sql`](rag/sample-curriculum-chunks.sql).
3. Generate embeddings for `knowledge_chunks.embedding`.
4. Add the retrieval nodes from [`n8n/rag-query-addon.md`](n8n/rag-query-addon.md).

Starter chunks are included without embeddings, so they will not appear in vector search until embeddings are generated.

## Roadmap

- **MVP:** Telegram tutor, Supabase memory, Socratic prompt, basic scoring.
- **V1:** automatic embeddings, misconception taxonomy, assessment bank, teacher dashboard.
- **V2:** RAGFlow ingestion, reranking, bilingual tutoring, spaced repetition.
- **Production:** evaluation set, rate limits, privacy review, observability, backups.

See [`docs/roadmap.md`](docs/roadmap.md) for the fuller plan.

## Security

Never commit real credentials. Use `.env.example` as a template and store actual API keys inside n8n credentials or your deployment secret manager.
