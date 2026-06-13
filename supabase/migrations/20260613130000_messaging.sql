-- ============================================================================
--  Фаза 3: личные сообщения (conversations / messages) + RLS + Realtime + RPC
--  Идемпотентная миграция.
-- ============================================================================

-- ── 1. Таблицы ──────────────────────────────────────────────────────────────
create table if not exists public.conversations (
  id         bigint generated always as identity primary key,
  is_group   boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.conversation_participants (
  conversation_id bigint not null references public.conversations (id) on delete cascade,
  user_id         uuid not null references public.profiles (id) on delete cascade,
  last_read_at    timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create index if not exists conv_participants_user_idx
  on public.conversation_participants (user_id);

create table if not exists public.messages (
  id              bigint generated always as identity primary key,
  conversation_id bigint not null references public.conversations (id) on delete cascade,
  sender_id       uuid not null references public.profiles (id) on delete cascade,
  content         text not null,
  image_url       text,
  created_at      timestamptz not null default now()
);

create index if not exists messages_conv_idx
  on public.messages (conversation_id, created_at desc);

-- ── 2. Хелпер участия (SECURITY DEFINER, чтобы избежать рекурсии в RLS) ──────
create or replace function public.is_participant(p_conversation bigint, p_user uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_participants
    where conversation_id = p_conversation and user_id = p_user
  );
$$;

-- ── 3. RLS ──────────────────────────────────────────────────────────────────
alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;

-- conversations: видит только участник
drop policy if exists "conversations_select_participant" on public.conversations;
create policy "conversations_select_participant"
  on public.conversations for select
  using (public.is_participant(id, auth.uid()));

-- participants: пользователь видит строки тех бесед, где он сам участник
drop policy if exists "participants_select" on public.conversation_participants;
create policy "participants_select"
  on public.conversation_participants for select
  using (public.is_participant(conversation_id, auth.uid()));

-- participants: пользователь может обновлять только свою строку (last_read_at)
drop policy if exists "participants_update_own" on public.conversation_participants;
create policy "participants_update_own"
  on public.conversation_participants for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- messages: чтение только участникам беседы
drop policy if exists "messages_select_participant" on public.messages;
create policy "messages_select_participant"
  on public.messages for select
  using (public.is_participant(conversation_id, auth.uid()));

-- messages: отправлять может только участник от своего имени
drop policy if exists "messages_insert_participant" on public.messages;
create policy "messages_insert_participant"
  on public.messages for insert
  with check (
    auth.uid() = sender_id
    and public.is_participant(conversation_id, auth.uid())
  );

-- ── 4. RPC: получить или создать личную беседу с другим пользователем ────────
create or replace function public.get_or_create_direct_conversation(other_user uuid)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me   uuid := auth.uid();
  v_conv bigint;
begin
  if v_me is null then
    raise exception 'not authenticated';
  end if;
  if other_user = v_me then
    raise exception 'cannot message yourself';
  end if;

  -- Существующая личная беседа ровно с этими двумя участниками.
  select c.id into v_conv
  from public.conversations c
  join public.conversation_participants p1
    on p1.conversation_id = c.id and p1.user_id = v_me
  join public.conversation_participants p2
    on p2.conversation_id = c.id and p2.user_id = other_user
  where c.is_group = false
  limit 1;

  if v_conv is not null then
    return v_conv;
  end if;

  insert into public.conversations (is_group) values (false) returning id into v_conv;
  insert into public.conversation_participants (conversation_id, user_id)
  values (v_conv, v_me), (v_conv, other_user);

  return v_conv;
end;
$$;

-- ── 5. Realtime ─────────────────────────────────────────────────────────────
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'conversation_participants'
  ) then
    alter publication supabase_realtime add table public.conversation_participants;
  end if;
end $$;
