insert into concepts (code, title, difficulty, curriculum_tags)
values
  ('natural_hazards', 'Natural hazards', 1, array['geography', 'disasters']),
  ('disaster_risk', 'Disaster risk', 2, array['hazard', 'vulnerability', 'exposure', 'capacity']),
  ('earthquake_basics', 'Earthquake basics', 1, array['earthquake', 'plate tectonics']),
  ('plate_boundaries', 'Plate boundaries', 2, array['earthquake', 'volcano', 'tectonics']),
  ('seismic_waves', 'Seismic waves', 3, array['earthquake']),
  ('volcano_basics', 'Volcano basics', 1, array['volcano']),
  ('volcanic_eruptions', 'Volcanic eruptions', 2, array['volcano', 'hazards']),
  ('flood_basics', 'Flood basics', 1, array['flood', 'hydrology']),
  ('river_flooding', 'River flooding', 2, array['flood', 'river']),
  ('flash_flooding', 'Flash flooding', 2, array['flood', 'rainfall']),
  ('tsunami_basics', 'Tsunami basics', 2, array['tsunami', 'earthquake', 'ocean']),
  ('landslide_basics', 'Landslide basics', 2, array['landslide', 'slope']),
  ('climate_hazards', 'Climate hazards', 2, array['climate', 'drought', 'heatwave', 'storm']),
  ('hazard_mitigation', 'Hazard mitigation', 2, array['mitigation', 'preparedness']),
  ('early_warning_systems', 'Early warning systems', 3, array['warning', 'preparedness']),
  ('case_study_indonesia', 'Indonesia disaster case studies', 3, array['case study', 'Indonesia'])
on conflict (code) do update set
  title = excluded.title,
  difficulty = excluded.difficulty,
  curriculum_tags = excluded.curriculum_tags;

update concepts child
set parent_concept_id = parent.id
from concepts parent
where child.code in ('earthquake_basics', 'volcano_basics', 'flood_basics', 'tsunami_basics', 'landslide_basics', 'climate_hazards')
  and parent.code = 'natural_hazards';

