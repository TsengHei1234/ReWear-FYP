-- ReWear MVP — Row Level Security (Database Reference §11).
-- Every table: users access only rows where user_id = auth.uid().
-- profiles: only the row where id = auth.uid().
-- Child tables also guard against linking to another user's item/outfit.

-- ── profiles ───────────────────────────────────────────────────
alter table public.profiles enable row level security;

create policy "profiles_select_own" on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id);

create policy "profiles_insert_own" on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) = id);

create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- ── items ──────────────────────────────────────────────────────
alter table public.items enable row level security;

create policy "items_select_own" on public.items
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "items_insert_own" on public.items
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "items_update_own" on public.items
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "items_delete_own" on public.items
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ── outfit_logs ────────────────────────────────────────────────
alter table public.outfit_logs enable row level security;

create policy "outfit_logs_select_own" on public.outfit_logs
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "outfit_logs_insert_own" on public.outfit_logs
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "outfit_logs_update_own" on public.outfit_logs
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "outfit_logs_delete_own" on public.outfit_logs
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ── item_events (with cross-link guard) ────────────────────────
alter table public.item_events enable row level security;

create policy "item_events_select_own" on public.item_events
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "item_events_insert_own" on public.item_events
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.items i
      where i.id = item_id and i.user_id = (select auth.uid())
    )
    and (
      outfit_log_id is null
      or exists (
        select 1 from public.outfit_logs ol
        where ol.id = outfit_log_id and ol.user_id = (select auth.uid())
      )
    )
  );

create policy "item_events_update_own" on public.item_events
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "item_events_delete_own" on public.item_events
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ── outfit_log_items (with cross-link guard) ───────────────────
alter table public.outfit_log_items enable row level security;

create policy "outfit_log_items_select_own" on public.outfit_log_items
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "outfit_log_items_insert_own" on public.outfit_log_items
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.outfit_logs ol
      where ol.id = outfit_log_id and ol.user_id = (select auth.uid())
    )
    and exists (
      select 1 from public.items i
      where i.id = item_id and i.user_id = (select auth.uid())
    )
  );

create policy "outfit_log_items_delete_own" on public.outfit_log_items
  for delete to authenticated
  using ((select auth.uid()) = user_id);
