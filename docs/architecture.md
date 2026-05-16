# Architecture

GeoAITutoring is built as a stateful tutoring loop. Telegram handles the student interface, n8n controls the workflow and learning policy, Supabase stores student state, and the LLM produces short Socratic responses under strict constraints.

## Runtime Flow

```text
Telegram student
-> Telegram Bot
-> n8n Telegram Trigger
-> Load or create student_profiles row
-> Prepare adaptive context
-> Handle Telegram commands when present
-> Embed the student query
-> Retrieve curriculum context from lesson_chunks
-> Format RAG context
-> Generate Socratic tutor reply
-> Run guardrail gate
-> Update student state, mastery, misconceptions, and completed topics
-> Send Telegram reply
```

## Core Design Choice

n8n owns the teaching policy. The LLM owns wording.

This keeps the tutor from answering too early. n8n prepares the attempt count, response mode, misconception context, lesson context, language preference, and spaced repetition cue. The tutor prompt then generates a Telegram-ready response that follows those constraints.

| Learning State | Allowed Action |
| --- | --- |
| Low mastery | Ask a guiding question |
| Confused, few hints used | Give a hint |
| Stuck after multiple hints | Give a micro-explanation |
| Misconception detected | Correct misconception gently |
| High mastery | Move to assessment |

The v3 workflow expresses these states as response modes:

- `socratic_question`
- `hint`
- `explain_concept`
- `partial_answer`
- `full_answer`

## Data Ownership

Supabase stores:

- Telegram identity mapping
- student profiles
- chat history
- attempt counts
- mastery score
- current topic
- misconception records
- completed topics
- lesson chunks and sources for RAG

## Knowledge Base

The recommended v3 workflow uses Supabase Vector/pgvector through `lesson_chunks` and lesson similarity search. RAGFlow can be added later for complex textbooks, scanned PDFs, diagrams, tables, and citation-heavy ingestion.

## Optional Langflow

Langflow is not required for the MVP. Add it only if you want a separate visual environment for tutor-chain experiments, retriever/reranker variants, or a reusable tutor API called by n8n.
