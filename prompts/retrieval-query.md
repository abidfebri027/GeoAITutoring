# Retrieval Query Prompt

Rewrite the student message into a short search query for a geography disaster knowledge base.

Include:
- disaster type if present
- core concept
- grade-appropriate wording
- likely misconception if present

Return JSON only:

{
  "query": "earthquake plate boundary stress release middle school",
  "disaster_type": "earthquake",
  "max_difficulty": 3
}

