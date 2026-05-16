insert into knowledge_documents (title, source_type, curriculum_level, disaster_type, metadata)
values
  ('Starter geography disaster curriculum', 'manual', 'middle_school', 'mixed', '{"source_reliability":"starter"}')
on conflict do nothing;

with doc as (
  select id from knowledge_documents
  where title = 'Starter geography disaster curriculum'
  order by created_at desc
  limit 1
)
insert into knowledge_chunks (
  document_id,
  content,
  chunk_type,
  concept_codes,
  disaster_type,
  difficulty,
  citation,
  metadata
)
select
  doc.id,
  chunk.content,
  chunk.chunk_type,
  chunk.concept_codes,
  chunk.disaster_type,
  chunk.difficulty,
  chunk.citation,
  chunk.metadata
from doc
cross join (
  values
  (
    'Earthquakes happen when stress builds up along faults or plate boundaries and is suddenly released. The released energy travels as seismic waves, which shake the ground. A useful Socratic path is: plates move, faults can get stuck, stress accumulates, then sudden slip releases energy.',
    'explanation',
    array['earthquake_basics', 'plate_boundaries'],
    'earthquake',
    1,
    'Starter curriculum: earthquake basics',
    '{"teaching_use":"guided_question"}'::jsonb
  ),
  (
    'A tsunami is usually caused by sudden displacement of a large volume of water, often from an undersea earthquake, volcanic eruption, or landslide. Wind creates ordinary surface waves, but tsunami waves involve movement through the whole water column.',
    'misconception',
    array['tsunami_basics', 'earthquake_basics'],
    'tsunami',
    2,
    'Starter curriculum: tsunami misconception',
    '{"common_misconception":"tsunamis are caused mainly by wind"}'::jsonb
  ),
  (
    'Flood risk increases when heavy rainfall, saturated soil, poor drainage, river overflow, or land-use changes cause water to accumulate faster than it can drain away. Mitigation can include drainage improvement, floodplain zoning, early warnings, and evacuation planning.',
    'explanation',
    array['flood_basics', 'hazard_mitigation'],
    'flood',
    2,
    'Starter curriculum: flood risk',
    '{"teaching_use":"cause_effect"}'::jsonb
  ),
  (
    'Volcanic hazards include lava flows, ash fall, pyroclastic flows, lahars, and volcanic gases. Students often focus only on lava, but ash, lahars, and pyroclastic flows can affect people far from the crater and may be more dangerous.',
    'explanation',
    array['volcano_basics', 'volcanic_eruptions'],
    'volcano',
    2,
    'Starter curriculum: volcanic hazards',
    '{"teaching_use":"misconception_repair"}'::jsonb
  )
) as chunk(content, chunk_type, concept_codes, disaster_type, difficulty, citation, metadata);

