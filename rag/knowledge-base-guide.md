# Knowledge Base Guide

## Recommended MVP

Use Supabase Vector/pgvector first because the student profile, chat memory, mastery, and RAG chunks can live in one Postgres project.

Use RAGFlow later if your source materials are mostly textbooks, scanned PDFs, slide decks, diagrams, and tables that need OCR/layout-aware parsing.

## Content Types To Store

- Curriculum explanations
- Guided examples
- Common misconceptions
- Disaster case studies
- Diagram descriptions
- Assessment questions
- Rubrics and model reasoning chains

## Chunking Rules

Use small, pedagogically meaningful chunks:

- Explanation: 150-350 words
- Case study: one event aspect per chunk
- Diagram: one visual relationship per chunk
- Question: one question plus answer/rubric per chunk
- Misconception: one misconception plus correction strategy per chunk

## Metadata

Every chunk should include:

```json
{
  "concept_codes": ["earthquake_basics", "plate_boundaries"],
  "disaster_type": "earthquake",
  "difficulty": 2,
  "chunk_type": "explanation",
  "curriculum_level": "middle_school",
  "region": "Indonesia",
  "source_reliability": "curriculum"
}
```

## Retrieval Strategy

1. Rewrite the student message into a retrieval query.
2. Embed the query.
3. Retrieve 4-8 chunks with metadata filters.
4. Prefer chunks at or slightly above the student's current difficulty.
5. Feed retrieved chunks into the Socratic tutor prompt.
6. Do not let the model answer outside the retrieved curriculum for factual case-study claims.

## Starter Topics

- Earthquake: stress buildup, fault rupture, seismic waves, plate boundaries.
- Volcano: magma, pressure, eruption types, ash/lava/lahar hazards.
- Flood: rainfall, drainage, river discharge, land use, mitigation.
- Tsunami: undersea earthquake, water displacement, wave shoaling.
- Landslide: slope, saturation, gravity, deforestation, warning signs.
- Mitigation: hazard maps, evacuation routes, early warning, preparedness.

