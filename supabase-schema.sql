-- Run this in Supabase Dashboard → SQL Editor (one-time setup)

-- Categories: one row per category per user
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz default now()
);

-- Expenses: one row per expense per user
create table if not exists public.expenses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric not null,
  category text not null,
  name text,
  date text not null,
  timestamp bigint not null,
  created_at timestamptz default now()
);

-- If table already existed without name, run this in SQL Editor:
-- alter table public.expenses add column if not exists name text;

-- Row Level Security: users only see their own data
alter table public.categories enable row level security;
alter table public.expenses enable row level security;

drop policy if exists "Users can manage own categories" on public.categories;
create policy "Users can manage own categories"
  on public.categories for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can manage own expenses" on public.expenses;
create policy "Users can manage own expenses"
  on public.expenses for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- User preferences (e.g. theme) per user
create table if not exists public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  theme_bg text default '#f3f4f6',
  theme_text text default '#111827',
  theme_surface text default '#ffffff',
  updated_at timestamptz default now()
);

alter table public.user_preferences enable row level security;

drop policy if exists "Users can manage own preferences" on public.user_preferences;
create policy "Users can manage own preferences"
  on public.user_preferences for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Optional: allow anonymous sign-in (Dashboard → Authentication → Providers → Anonymous)
-- If enabled, users get a persistent anonymous id and data syncs across browser sessions on same device.
-- For same data on mobile + web, use Email or OAuth sign-in instead.
