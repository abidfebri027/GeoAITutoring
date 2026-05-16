# Roadmap

## MVP - Completed Proof of Concept

The current MVP demonstrates that the core tutoring loop works end to end through Telegram.

Implemented:

- Telegram bot as the student interface
- n8n workflow for the Socratic tutoring loop
- Supabase/Postgres memory for persistent student state
- Socratic prompt with direct-answer prevention
- adaptive attempt tracking from guiding questions to hints, explanations, partial answers, and full answers
- misconception guardrails for common Earth Science and disaster-geography misunderstandings
- basic mastery scoring and state updates after each exchange

This phase validates the central idea: the tutor can guide students through reasoning instead of immediately giving final answers.

## V1 - Learning Intelligence Research

The next research phase should focus on making the learning diagnosis more structured and useful for teachers.

Research and development directions:

- automatic embedding workflow for curriculum materials
- structured misconception taxonomy for geography and disaster topics
- assessment question bank mapped to concepts and difficulty levels
- teacher dashboard for mastery, misconception frequency, attempt history, and progress trends
- progress summaries that help teachers identify students who need intervention

The goal of V1 is to move from a working tutor prototype to a measurable adaptive learning system.

## V2 - Advanced RAG and Personalization Research

The second research phase should improve knowledge retrieval, language accessibility, and long-term learning support.

Research and development directions:

- RAGFlow ingestion for textbooks, PDFs, tables, diagrams, and scanned learning materials
- reranking to improve the relevance and accuracy of retrieved disaster-geography content
- citation display for teacher review and curriculum traceability
- Indonesian and English tutoring modes for bilingual classroom use
- spaced repetition reminders through Telegram to reinforce weak concepts over time
- classroom and group support for multiple students and cohorts

The goal of V2 is to make the tutor more curriculum-grounded, more personalized, and more useful beyond a single chat session.

## Production - Deployment and Safety Research

The production phase should prepare the system for dependable classroom or institutional use.

Research and development directions:

- prompt versioning and evaluation test sets to measure tutor quality over time
- rate limiting and abuse controls for stable Telegram usage
- privacy review, retention policy, and student data protection practices
- backup and restore process for database reliability
- cost, latency, and model-failure monitoring
- deployment runbook for operating n8n, Supabase, and model credentials safely

The goal of this phase is to turn the research prototype into a reliable, observable, and responsibly managed education system.
