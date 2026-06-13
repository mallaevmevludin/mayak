-- ============================================================================
--  Фаза 2: подписки (follows), уведомления (notifications) и Realtime
--  Идемпотентная миграция — безопасно прогонять повторно.
--  Применить: Supabase Dashboard → SQL Editor, или `supabase db push`.
-- ============================================================================

-- ── 1. Таблица подписок ─────────────────────────────────────────────────────
create table if not exists public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  followee_id uuid not null references public.profiles (id) on delete cascade,
  created_at  timestamptz not null default now(),
  primary key (follower_id, followee_id),
  constraint follows_no_self check (follower_id <> followee_id)
);

create index if not exists follows_followee_idx on public.follows (followee_id);
create index if not exists follows_follower_idx on public.follows (follower_id);

alter table public.follows enable row level security;

drop policy if exists "follows_select_all" on public.follows;
create policy "follows_select_all"
  on public.follows for select
  using (true);

drop policy if exists "follows_insert_own" on public.follows;
create policy "follows_insert_own"
  on public.follows for insert
  with check (auth.uid() = follower_id);

drop policy if exists "follows_delete_own" on public.follows;
create policy "follows_delete_own"
  on public.follows for delete
  using (auth.uid() = follower_id);

-- ── 2. Таблица уведомлений ──────────────────────────────────────────────────
--  type: 'like' | 'comment' | 'follow' | 'mention'
create table if not exists public.notifications (
  id         bigint generated always as identity primary key,
  user_id    uuid not null references public.profiles (id) on delete cascade, -- получатель
  actor_id   uuid not null references public.profiles (id) on delete cascade, -- кто инициировал
  type       text not null check (type in ('like', 'comment', 'follow', 'mention')),
  post_id    bigint,
  comment_id bigint,
  is_read    boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_idx
  on public.notifications (user_id, created_at desc);

alter table public.notifications enable row level security;

-- Получатель видит и помечает прочитанными только свои уведомления.
drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
  on public.notifications for select
  using (auth.uid() = user_id);

drop policy if exists "notifications_update_own" on public.notifications;
create policy "notifications_update_own"
  on public.notifications for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── 3. Триггеры: автосоздание уведомлений ───────────────────────────────────
-- Уведомления создаёт триггер (SECURITY DEFINER), поэтому отдельная
-- insert-политика для клиента не нужна.

-- Подписка → уведомление получателю
create or replace function public.notify_on_follow()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.notifications (user_id, actor_id, type)
  values (new.followee_id, new.follower_id, 'follow');
  return new;
end;
$$;

create or replace trigger trg_notify_on_follow
  after insert on public.follows
  for each row execute function public.notify_on_follow();

-- Лайк поста → уведомление автору (не себе)
create or replace function public.notify_on_post_like()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_author uuid;
begin
  select user_id into v_author from public.posts where id = new.post_id;
  if v_author is not null and v_author <> new.user_id then
    insert into public.notifications (user_id, actor_id, type, post_id)
    values (v_author, new.user_id, 'like', new.post_id);
  end if;
  return new;
end;
$$;

create or replace trigger trg_notify_on_post_like
  after insert on public.post_likes
  for each row execute function public.notify_on_post_like();

-- Комментарий → уведомление автору поста (не себе)
create or replace function public.notify_on_comment()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_author uuid;
begin
  select user_id into v_author from public.posts where id = new.post_id;
  if v_author is not null and v_author <> new.user_id then
    insert into public.notifications (user_id, actor_id, type, post_id, comment_id)
    values (v_author, new.user_id, 'comment', new.post_id, new.id);
  end if;
  return new;
end;
$$;

create or replace trigger trg_notify_on_comment
  after insert on public.comments
  for each row execute function public.notify_on_comment();

-- ── 4. Realtime ─────────────────────────────────────────────────────────────
-- Добавляем таблицы в публикацию supabase_realtime (если ещё не добавлены).
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'posts'
  ) then
    alter publication supabase_realtime add table public.posts;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'post_likes'
  ) then
    alter publication supabase_realtime add table public.post_likes;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'comments'
  ) then
    alter publication supabase_realtime add table public.comments;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'follows'
  ) then
    alter publication supabase_realtime add table public.follows;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
