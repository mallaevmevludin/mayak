// Edge Function: отправка push-уведомления получателю при новом сообщении.
//
// Триггерится Database Webhook (INSERT на public.messages). Находит
// собеседников беседы (кроме отправителя), берёт их device_tokens и шлёт push
// через FCM (legacy HTTP API).
//
// ── Настройка (выполнить один раз) ──────────────────────────────────────────
// 1) Получить FCM server key (Firebase Console → Project Settings → Cloud
//    Messaging → Server key) и задать секрет:
//      supabase secrets set FCM_SERVER_KEY=xxxxx
// 2) Задеплоить функцию:
//      supabase functions deploy notify-on-message --no-verify-jwt
// 3) Dashboard → Database → Webhooks → Create:
//      table: public.messages, events: INSERT,
//      type: Supabase Edge Functions → notify-on-message.
//
// SUPABASE_URL и SUPABASE_SERVICE_ROLE_KEY доступны в окружении функции
// автоматически.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface MessageRecord {
  id: number;
  conversation_id: number;
  sender_id: string;
  content: string;
}

Deno.serve(async (req: Request) => {
  try {
    const payload = await req.json();
    const message: MessageRecord = payload.record ?? payload;
    if (!message?.conversation_id || !message?.sender_id) {
      return new Response("ignored", { status: 200 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Получатели = участники беседы, кроме отправителя.
    const { data: participants } = await supabase
      .from("conversation_participants")
      .select("user_id")
      .eq("conversation_id", message.conversation_id)
      .neq("user_id", message.sender_id);

    const recipientIds = (participants ?? []).map((p) => p.user_id);
    if (recipientIds.length === 0) {
      return new Response("no recipients", { status: 200 });
    }

    // Имя отправителя для заголовка.
    const { data: sender } = await supabase
      .from("profiles")
      .select("first_name, last_name, username")
      .eq("id", message.sender_id)
      .single();
    const senderName =
      [sender?.first_name, sender?.last_name].filter(Boolean).join(" ") ||
      sender?.username ||
      "Новое сообщение";

    // Токены устройств получателей.
    const { data: tokens } = await supabase
      .from("device_tokens")
      .select("token")
      .in("user_id", recipientIds);

    const fcmKey = Deno.env.get("FCM_SERVER_KEY");
    if (!fcmKey || !tokens || tokens.length === 0) {
      return new Response("nothing to send", { status: 200 });
    }

    await Promise.all(
      tokens.map((t) =>
        fetch("https://fcm.googleapis.com/fcm/send", {
          method: "POST",
          headers: {
            "Authorization": `key=${fcmKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            to: t.token,
            notification: {
              title: senderName,
              body: message.content.slice(0, 140),
            },
            data: { conversation_id: String(message.conversation_id) },
          }),
        })
      ),
    );

    return new Response("sent", { status: 200 });
  } catch (e) {
    console.error("notify-on-message error", e);
    return new Response("error", { status: 500 });
  }
});
