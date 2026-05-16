# Architecture

GeoAITutoring is built as a stateful tutoring loop. Telegram handles the student interface, n8n controls the workflow and learning policy, Supabase stores student state, and the LLM produces short Socratic responses under strict constraints.

## Runtime Flow

```text
Telegram student
-> Telegram Bot
-> n8n Telegram Trigger
-> Normalize Telegram input
-> Get or create Supabase student profile
-> Get or create active tutoring session
-> Save student message
-> Load recent chat, profile, and mastery
-> Retrieve curriculum context when RAG is enabled
-> Compute pedagogy policy
-> Generate Socratic tutor reply
-> Send Telegram reply
-> Save assistant message
-> Score latest student response
-> Update mastery, misconceptions, and scoring history
```

## Core Design Choice

n8n owns the teaching policy. The LLM owns wording.

This keeps the tutor from answering too early. n8n calculates an `allowed_action`, then the tutor prompt generates a Telegram-ready response that follows that action.

| Learning State | Allowed Action |
| --- | --- |
| Low mastery | Ask a guiding question |
| Confused, few hints used | Give a hint |
| Stuck after multiple hints | Give a micro-explanation |
| Misconception detected | Correct misconception gently |
| High mastery | Move to assessment |

## Data Ownership

Supabase stores:

- Telegram identity mapping
- student profiles
- chat history
- tutoring sessions
- concept mastery
- misconception records
- assessment results
- scoring history
- RAG documents and chunks

## Knowledge Base

The MVP uses Supabase Vector/pgvector so application data and retrieval data stay together. RAGFlow can be added later for complex textbooks, scanned PDFs, diagrams, tables, and citation-heavy ingestion.

## Optional Langflow

Langflow is not required for the MVP. Add it only if you want a separate visual environment for tutor-chain experiments, retriever/reranker variants, or a reusable tutor API called by n8n.

