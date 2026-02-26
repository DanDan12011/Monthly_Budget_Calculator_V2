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
  date text not null,
  timestamp bigint not null,
  created_at timestamptz default now()
);

-- Row Level Security: users only see their own data
alter table public.categories enable row level security;
alter table public.expenses enable row level security;

create policy "Users can manage own categories"
  on public.categories for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can manage own expenses"
  on public.expenses for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Optional: allow anonymous sign-in (Dashboard → Authentication → Providers → Anonymous)
-- If enabled, users get a persistent anonymous id and data syncs across browser sessions on same device.
-- For same data on mobile + web, use Email or OAuth sign-in instead.
