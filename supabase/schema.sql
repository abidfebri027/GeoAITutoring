create extension if not exists vector;
create extension if not exists pgcrypto;

create table if not exists students (
  id uuid primary key default gen_random_uuid(),
  email text unique,
  name text,
  grade_level text default 'middle_school',
  language text default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists student_telegram_accounts (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  telegram_user_id text unique not null,
  telegram_chat_id text not null,
  telegram_username text,
  first_name text,
  last_name text,
  linked_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create table if not exists student_profiles (
  student_id uuid primary key references students(id) on delete cascade,
  learning_style text default 'guided_questioning',
  preferred_difficulty int not null default 2 check (preferred_difficulty between 1 and 5),
  confidence_baseline numeric not null default 0.50 check (confidence_baseline between 0 and 1),
  notes jsonb not null default '{}',
  updated_at timestamptz not null default now()
);

create table if not exists concepts (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  title text not null,
  domain text not null default 'geography_disasters',
  parent_concept_id uuid references concepts(id),
  difficulty int not null default 1 check (difficulty between 1 and 5),
  curriculum_tags text[] not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists student_concept_mastery (
  student_id uuid not null references students(id) on delete cascade,
  concept_id uuid not null references concepts(id) on delete cascade,
  mastery_score numeric not null default 0 check (mastery_score between 0 and 1),
  confidence_score numeric not null default 0 check (confidence_score between 0 and 1),
  misconception_count int not null default 0,
  hints_used_total int not null default 0,
  attempts_total int not null default 0,
  last_practiced_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (student_id, concept_id)
);

create table if not exists tutoring_sessions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  telegram_chat_id text,
  topic text,
  current_concept_id uuid references concepts(id),
  tutor_mode text not null default 'socratic',
  status text not null default 'active',
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

create table if not exists chat_messages (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references tutoring_sessions(id) on delete set null,
  student_id uuid references students(id) on delete cascade,
  telegram_message_id text,
  role text not null check (role in ('student', 'assistant', 'system')),
  content text not null,
  tutor_action text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists misconceptions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  concept_id uuid references concepts(id) on delete set null,
  misconception_type text not null,
  evidence_message_id uuid references chat_messages(id) on delete set null,
  severity int not null default 1 check (severity between 1 and 5),
  status text not null default 'active',
  remediation_notes text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists assessments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  concept_id uuid references concepts(id) on delete set null,
  session_id uuid references tutoring_sessions(id) on delete set null,
  question text not null,
  student_answer text not null,
  rubric jsonb not null default '{}',
  score numeric not null check (score between 0 and 1),
  created_at timestamptz not null default now()
);

create table if not exists scoring_history (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  concept_id uuid references concepts(id) on delete set null,
  session_id uuid references tutoring_sessions(id) on delete set null,
  message_id uuid references chat_messages(id) on delete set null,
  conceptual_accuracy numeric not null default 0 check (conceptual_accuracy between 0 and 1),
  reasoning_quality numeric not null default 0 check (reasoning_quality between 0 and 1),
  use_of_evidence numeric not null default 0 check (use_of_evidence between 0 and 1),
  confidence_calibration numeric not null default 0 check (confidence_calibration between 0 and 1),
  independence numeric not null default 0 check (independence between 0 and 1),
  improvement numeric not null default 0 check (improvement between 0 and 1),
  hints_used int not null default 0,
  misconceptions_detected int not null default 0,
  final_score numeric not null check (final_score between 0 and 1),
  raw_evaluation jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists knowledge_documents (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  source_type text not null,
  curriculum_level text,
  disaster_type text,
  source_url text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now()
);

create table if not exists knowledge_chunks (
  id uuid primary key default gen_random_uuid(),
  document_id uuid references knowledge_documents(id) on delete cascade,
  content text not null,
  chunk_type text not null default 'explanation',
  concept_codes text[] not null default '{}',
  disaster_type text,
  difficulty int not null default 1 check (difficulty between 1 and 5),
  citation text,
  metadata jsonb not null default '{}',
  embedding vector(1536),
  created_at timestamptz not null default now()
);

create index if not exists idx_telegram_user_id on student_telegram_accounts(telegram_user_id);
create index if not exists idx_chat_student_created on chat_messages(student_id, created_at desc);
create index if not exists idx_mastery_student on student_concept_mastery(student_id);
create index if not exists idx_concepts_code on concepts(code);
create index if not exists idx_chunks_disaster_type on knowledge_chunks(disaster_type);
create index if not exists idx_chunks_concepts on knowledge_chunks using gin(concept_codes);
create index if not exists idx_chunks_embedding_hnsw on knowledge_chunks using hnsw (embedding vector_cosine_ops);

create or replace function touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists students_touch_updated_at on students;
create trigger students_touch_updated_at
before update on students
for each row execute function touch_updated_at();

drop trigger if exists profiles_touch_updated_at on student_profiles;
create trigger profiles_touch_updated_at
before update on student_profiles
for each row execute function touch_updated_at();

create or replace function get_or_create_telegram_student(
  p_telegram_user_id text,
  p_telegram_chat_id text,
  p_username text,
  p_first_name text,
  p_last_name text
)
returns table (
  student_id uuid,
  telegram_account_id uuid,
  display_name text
)
language plpgsql
as $$
declare
  v_student_id uuid;
  v_account_id uuid;
  v_display_name text;
begin
  v_display_name := trim(coalesce(p_first_name, '') || ' ' || coalesce(p_last_name, ''));
  if v_display_name = '' then
    v_display_name := coalesce(p_username, 'Telegram Student');
  end if;

  select sta.student_id, sta.id
  into v_student_id, v_account_id
  from student_telegram_accounts sta
  where sta.telegram_user_id = p_telegram_user_id;

  if v_student_id is null then
    insert into students (name)
    values (v_display_name)
    returning id into v_student_id;

    insert into student_profiles (student_id)
    values (v_student_id);

    insert into student_telegram_accounts (
      student_id,
      telegram_user_id,
      telegram_chat_id,
      telegram_username,
      first_name,
      last_name
    )
    values (
      v_student_id,
      p_telegram_user_id,
      p_telegram_chat_id,
      p_username,
      p_first_name,
      p_last_name
    )
    returning id into v_account_id;
  else
    update student_telegram_accounts
    set telegram_chat_id = p_telegram_chat_id,
        telegram_username = p_username,
        first_name = p_first_name,
        last_name = p_last_name,
        last_seen_at = now()
    where id = v_account_id;
  end if;

  return query select v_student_id, v_account_id, v_display_name;
end;
$$;

create or replace function get_or_create_active_session(
  p_student_id uuid,
  p_telegram_chat_id text,
  p_topic text default null
)
returns uuid
language plpgsql
as $$
declare
  v_session_id uuid;
begin
  select id into v_session_id
  from tutoring_sessions
  where student_id = p_student_id
    and telegram_chat_id = p_telegram_chat_id
    and status = 'active'
  order by started_at desc
  limit 1;

  if v_session_id is null then
    insert into tutoring_sessions (student_id, telegram_chat_id, topic)
    values (p_student_id, p_telegram_chat_id, coalesce(p_topic, 'geography_disasters'))
    returning id into v_session_id;
  end if;

  return v_session_id;
end;
$$;

create or replace function match_knowledge_chunks(
  query_embedding vector(1536),
  match_count int default 6,
  filter_disaster_type text default null,
  filter_max_difficulty int default null
)
returns table (
  id uuid,
  content text,
  citation text,
  chunk_type text,
  concept_codes text[],
  disaster_type text,
  difficulty int,
  similarity numeric
)
language sql stable
as $$
  select
    kc.id,
    kc.content,
    kc.citation,
    kc.chunk_type,
    kc.concept_codes,
    kc.disaster_type,
    kc.difficulty,
    1 - (kc.embedding <=> query_embedding) as similarity
  from knowledge_chunks kc
  where kc.embedding is not null
    and (filter_disaster_type is null or kc.disaster_type = filter_disaster_type)
    and (filter_max_difficulty is null or kc.difficulty <= filter_max_difficulty)
  order by kc.embedding <=> query_embedding
  limit match_count;
$$;

create or replace function update_mastery_from_score(
  p_student_id uuid,
  p_concept_code text,
  p_final_score numeric,
  p_confidence numeric,
  p_hints_used int,
  p_misconceptions_detected int
)
returns table (
  concept_id uuid,
  mastery_score numeric,
  confidence_score numeric
)
language plpgsql
as $$
declare
  v_concept_id uuid;
begin
  select id into v_concept_id from concepts where code = p_concept_code;

  if v_concept_id is null then
    insert into concepts (code, title, difficulty)
    values (p_concept_code, initcap(replace(p_concept_code, '_', ' ')), 1)
    returning id into v_concept_id;
  end if;

  insert into student_concept_mastery (
    student_id,
    concept_id,
    mastery_score,
    confidence_score,
    misconception_count,
    hints_used_total,
    attempts_total,
    last_practiced_at
  )
  values (
    p_student_id,
    v_concept_id,
    least(1, greatest(0, p_final_score)),
    least(1, greatest(0, p_confidence)),
    greatest(0, p_misconceptions_detected),
    greatest(0, p_hints_used),
    1,
    now()
  )
  on conflict (student_id, concept_id)
  do update set
    mastery_score = round(((student_concept_mastery.mastery_score * 0.75) + (least(1, greatest(0, p_final_score)) * 0.25))::numeric, 4),
    confidence_score = round(((student_concept_mastery.confidence_score * 0.70) + (least(1, greatest(0, p_confidence)) * 0.30))::numeric, 4),
    misconception_count = student_concept_mastery.misconception_count + greatest(0, p_misconceptions_detected),
    hints_used_total = student_concept_mastery.hints_used_total + greatest(0, p_hints_used),
    attempts_total = student_concept_mastery.attempts_total + 1,
    last_practiced_at = now(),
    updated_at = now();

  return query
  select scm.concept_id, scm.mastery_score, scm.confidence_score
  from student_concept_mastery scm
  where scm.student_id = p_student_id and scm.concept_id = v_concept_id;
end;
$$;

