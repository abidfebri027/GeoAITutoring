-- ═══════════════════════════════════════════════════════════════════════════════
-- GeoAI RAG INFRASTRUCTURE SETUP
-- Run this once on your Postgres instance (same DB as student_profiles).
-- Requires: pgvector extension (available on Supabase, Neon, Railway, etc.)
-- ═══════════════════════════════════════════════════════════════════════════════

-- 1. Enable pgvector
-- ─────────────────────────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS vector;


-- 2. Lesson chunks table  (text-embedding-3-small → 1536 dims)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lesson_chunks (
  id           SERIAL PRIMARY KEY,
  topic        TEXT    NOT NULL,          -- must match TOPICS_SEQUENCE in n8n
  subtopic     TEXT,
  content      TEXT    NOT NULL,
  embedding    vector(1536),
  source       TEXT,                      -- e.g. 'Bab 3 - Lempeng Tektonik.pdf'
  grade_level  INTEGER DEFAULT 10,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ANN index for fast cosine similarity search
-- NOTE: Build this index AFTER you have loaded at least a few hundred rows.
--       lists ≈ sqrt(row_count) is a good rule of thumb.
CREATE INDEX IF NOT EXISTS lesson_chunks_embedding_idx
  ON lesson_chunks
  USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

-- B-tree index for topic pre-filtering
CREATE INDEX IF NOT EXISTS lesson_chunks_topic_idx
  ON lesson_chunks (topic);


-- 3. Source tracking table  (one row per ingested file)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lesson_sources (
  id          SERIAL PRIMARY KEY,
  filename    TEXT UNIQUE NOT NULL,
  topic       TEXT,
  chunk_count INTEGER DEFAULT 0,
  ingested_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4. Convenience search function  (called by n8n Search Lesson Chunks node)
-- ─────────────────────────────────────────────────────────────────────────────
-- Usage:
--   SELECT * FROM search_lesson_chunks(
--     query_embedding := '[0.1, 0.2, ...]'::vector,
--     topic_filter    := 'Plate Tectonics',
--     match_threshold := 0.6,
--     match_count     := 3
--   );
CREATE OR REPLACE FUNCTION search_lesson_chunks(
  query_embedding  vector(1536),
  topic_filter     TEXT    DEFAULT NULL,
  match_threshold  FLOAT   DEFAULT 0.55,
  match_count      INT     DEFAULT 3
)
RETURNS TABLE (
  id         INTEGER,
  topic      TEXT,
  subtopic   TEXT,
  content    TEXT,
  source     TEXT,
  similarity FLOAT
)
LANGUAGE sql STABLE
AS $$
  SELECT
    lc.id,
    lc.topic,
    lc.subtopic,
    lc.content,
    lc.source,
    1 - (lc.embedding <=> query_embedding) AS similarity
  FROM lesson_chunks lc
  WHERE
    (topic_filter IS NULL OR lc.topic ILIKE '%' || topic_filter || '%')
    AND 1 - (lc.embedding <=> query_embedding) > match_threshold
  ORDER BY lc.embedding <=> query_embedding
  LIMIT match_count;
$$;


-- 5. Sample seed data  (delete or replace with your actual curriculum)
-- ─────────────────────────────────────────────────────────────────────────────
-- These rows have no embedding yet. Run the ingestion n8n flow to generate
-- embeddings and upsert them. These are placeholder content examples only.

INSERT INTO lesson_chunks (topic, subtopic, content, source, grade_level) VALUES
(
  'Plate Tectonics',
  'Convection Currents',
  'Convection currents in the mantle are the primary driver of tectonic plate motion. Hot magma rises from the core-mantle boundary, spreads laterally, cools, and sinks back down. This circular motion drags the rigid lithospheric plates above it. Faster convection cells correlate with faster plate movement.',
  'Bab 2 - Lempeng Tektonik.pdf',
  10
),
(
  'Earthquakes',
  'Focus vs Epicenter',
  'An earthquake originates at the focus (or hypocenter), a point underground where the fault rupture begins. The epicenter is the point on the Earth''s surface directly above the focus. Seismic waves radiate outward from the focus in all directions. Ground shaking is typically most intense near the epicenter, but the energy source is the focus.',
  'Bab 3 - Gempa Bumi.pdf',
  10
),
(
  'Earthquakes',
  'Magnitude Scales',
  'The Richter scale was developed in 1935 and measures local magnitude (ML) using a seismograph. It is logarithmic: each whole number increase represents 10× greater ground motion and ~31.6× more energy. For large earthquakes (M > 6.5), the Richter scale saturates. Modern seismologists use the Moment Magnitude Scale (Mw), which remains accurate across all earthquake sizes and is based on seismic moment (area × slip × rigidity).',
  'Bab 3 - Gempa Bumi.pdf',
  10
),
(
  'Volcanoes',
  'Types of Volcanoes',
  'There are three main types: shield volcanoes (broad, gently sloping, formed from low-viscosity basaltic lava — e.g. Mauna Loa), stratovolcanoes/composite volcanoes (steep-sided, explosive, alternating ash and lava layers — e.g. Merapi, Fuji), and cinder cone volcanoes (small, steep, formed from pyroclastic fragments — e.g. Paricutin). Shield volcanoes form mainly at hotspots and divergent boundaries; stratovolcanoes form at subduction zones.',
  'Bab 4 - Vulkanisme.pdf',
  10
),
(
  'Tsunamis',
  'Formation Mechanism',
  'Tsunamis are triggered by sudden, large-scale vertical displacement of the ocean floor or water column. The primary causes are: (1) submarine earthquakes with Mw ≥ 7.0 and vertical fault motion (not all submarine earthquakes generate tsunamis — the fault must displace the seafloor vertically); (2) submarine or coastal landslides; (3) volcanic eruptions (caldera collapse or pyroclastic flows entering water); (4) rarely, large meteorite impacts. Wind-driven waves are NOT tsunamis.',
  'Bab 5 - Tsunami.pdf',
  10
),
(
  'Disaster Mitigation',
  'Early Warning Systems',
  'Indonesia''s National Disaster Management Agency (BNPB) operates an integrated multi-hazard early warning system. For tsunamis, BMKG uses seafloor pressure sensors (DART buoys), seismographs, and tide gauges to issue warnings within 5 minutes of a large submarine earthquake. Community-level mitigation includes evacuation route signs, periodic drills (gladi evakuasi), and Tsunami Ready community certification.',
  'Bab 8 - Mitigasi Bencana.pdf',
  10
)
ON CONFLICT DO NOTHING;


-- 6. Verify setup
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
  'lesson_chunks'  AS table_name,
  COUNT(*)         AS total_rows,
  COUNT(embedding) AS rows_with_embedding
FROM lesson_chunks

UNION ALL

SELECT
  'lesson_sources',
  COUNT(*),
  NULL
FROM lesson_sources;
