-- Run this once in Supabase SQL Editor. Family tree contents are public-read,
-- matching the current public GitHub Pages site. Only listed admin accounts
-- can update the shared state.
create table if not exists public.bandi_site_state (
  id integer primary key check (id = 1),
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.bandi_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

alter table public.bandi_site_state enable row level security;
alter table public.bandi_admins enable row level security;

drop policy if exists "Anyone can read family tree" on public.bandi_site_state;
create policy "Anyone can read family tree" on public.bandi_site_state
  for select to anon, authenticated using (true);

drop policy if exists "Admins can update family tree" on public.bandi_site_state;
create policy "Admins can update family tree" on public.bandi_site_state
  for all to authenticated
  using (exists (select 1 from public.bandi_admins a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.bandi_admins a where a.user_id = (select auth.uid())));

-- Keep admin membership private. Only the matching user can see their own row.
drop policy if exists "Admins can read own membership" on public.bandi_admins;
create policy "Admins can read own membership" on public.bandi_admins
  for select to authenticated using (user_id = (select auth.uid()));

grant select on public.bandi_site_state to anon, authenticated;
grant insert, update, delete on public.bandi_site_state to authenticated;
grant select on public.bandi_admins to authenticated;

