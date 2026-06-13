-- RPC: список личных бесед текущего пользователя с собеседником и последним
-- сообщением. Используется на экране списка чатов.
create or replace function public.get_my_conversations()
returns table (
  conversation_id bigint,
  other_id        uuid,
  other_first     text,
  other_last      text,
  other_username  text,
  other_avatar    text,
  other_emoji     text,
  other_verified  boolean,
  last_content    text,
  last_at         timestamptz,
  last_sender     uuid,
  last_read_at    timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    c.id,
    op.user_id,
    pr.first_name,
    pr.last_name,
    pr.username,
    pr.avatar_url,
    pr.emoji_avatar,
    pr.is_verified,
    lm.content,
    lm.created_at,
    lm.sender_id,
    myp.last_read_at
  from public.conversation_participants myp
  join public.conversations c on c.id = myp.conversation_id
  join public.conversation_participants op
    on op.conversation_id = c.id and op.user_id <> auth.uid()
  join public.profiles pr on pr.id = op.user_id
  left join lateral (
    select m.content, m.created_at, m.sender_id
    from public.messages m
    where m.conversation_id = c.id
    order by m.created_at desc
    limit 1
  ) lm on true
  where myp.user_id = auth.uid()
  order by coalesce(lm.created_at, c.created_at) desc;
$$;
