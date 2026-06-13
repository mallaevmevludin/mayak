-- ============================================================================
--  Фаза 4: полнотекстовый поиск (русский словарь) по профилям и вакансиям.
--  GIN-индексы по выражению + RPC, к которым обращается клиент.
--  Идемпотентная миграция.
-- ============================================================================

-- ── Профили ─────────────────────────────────────────────────────────────────
create index if not exists profiles_fts_idx on public.profiles
using gin (
  to_tsvector(
    'russian',
    coalesce(first_name, '') || ' ' ||
    coalesce(last_name, '') || ' ' ||
    coalesce(username, '')
  )
);

create or replace function public.search_profiles(q text)
returns setof public.profiles
language sql
stable
as $$
  select *
  from public.profiles
  where q is not null and length(trim(q)) > 0
    and (
      to_tsvector(
        'russian',
        coalesce(first_name, '') || ' ' ||
        coalesce(last_name, '') || ' ' ||
        coalesce(username, '')
      ) @@ websearch_to_tsquery('russian', q)
      or username ilike '%' || q || '%'
      or first_name ilike '%' || q || '%'
      or last_name ilike '%' || q || '%'
    )
  limit 20;
$$;

-- ── Вакансии ────────────────────────────────────────────────────────────────
create index if not exists jobs_fts_idx on public.jobs
using gin (
  to_tsvector(
    'russian',
    coalesce(title, '') || ' ' || coalesce(description, '')
  )
);

create or replace function public.search_jobs(q text)
returns setof public.jobs
language sql
stable
as $$
  select *
  from public.jobs
  where q is not null and length(trim(q)) > 0
    and (
      to_tsvector(
        'russian',
        coalesce(title, '') || ' ' || coalesce(description, '')
      ) @@ websearch_to_tsquery('russian', q)
      or title ilike '%' || q || '%'
    )
  order by created_at desc
  limit 40;
$$;
