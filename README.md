# Mayak (Маяк)

Мобильное и веб-приложение на **Flutter** с бэкендом **Supabase**: социальная лента, вакансии, профили пользователей и панель модерации на **Next.js**.

## Возможности

- **Авторизация** — регистрация, вход, подтверждение email, сброс пароля
- **Социальная лента** — посты, комментарии, упоминания, загрузка изображений
- **Вакансии** — просмотр, создание объявлений, фильтры по категориям
- **Поиск и профили** — пользователи, настройки, тёмная тема
- **Уведомления** — локальные push-напоминания
- **Админ-панель** (`admin/`) — модерация вакансий (ожидание / одобрение / отклонение)

## Стек

| Часть | Технологии |
|-------|------------|
| Клиент | Flutter 3, Provider, Supabase Flutter |
| Админка | Next.js, React, Supabase JS |
| Бэкенд | Supabase (Auth, Postgres, Storage, Edge Functions) |

## Структура репозитория

```
lib/              — Flutter UI и сервисы
admin/            — веб-панель модерации (Next.js)
supabase/         — Edge Functions (например, upload-image)
android/ ios/     — нативные оболочки
```

## Быстрый старт

### Flutter-приложение

1. Установите [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Скопируйте пример конфигурации Supabase:
   ```bash
   cp lib/services/supabase_local.example.dart lib/services/supabase_local.dart
   ```
3. Укажите URL и anon key проекта Supabase в `lib/services/supabase_local.dart`.
4. Запуск:
   ```bash
   flutter pub get
   flutter run
   ```

### Админ-панель

1. Перейдите в каталог `admin/`.
2. Скопируйте переменные окружения:
   ```bash
   cp .env.example .env.local
   ```
3. Заполните `NEXT_PUBLIC_SUPABASE_URL` и `NEXT_PUBLIC_SUPABASE_ANON_KEY` в `.env.local`.
4. Запуск:
   ```bash
   npm install
   npm run dev
   ```

Файлы `.env`, `.env.local` и `lib/services/supabase_local.dart` **не попадают в Git** — используйте только `.example` шаблоны в репозитории.

## Лицензия

Проект распространяется как есть. Уточните условия использования у владельца репозитория.

<!-- Создано с помощью OpenAI Codex и ChatGPT -->
