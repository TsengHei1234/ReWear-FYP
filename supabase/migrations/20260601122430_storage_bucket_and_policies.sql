-- Private bucket for clothing photos (Database Reference §12).
insert into storage.buckets (id, name, public)
values ('wardrobe-items', 'wardrobe-items', false)
on conflict (id) do nothing;

-- Owner-folder policies: path is {user_id}/{item_id}/main.jpg, so the first
-- folder segment must equal the caller's uid. INSERT+SELECT+UPDATE+DELETE so
-- upload, view, replace (upsert), and delete all work for the owner only.
create policy "wardrobe_items_select_own" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'wardrobe-items'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "wardrobe_items_insert_own" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'wardrobe-items'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "wardrobe_items_update_own" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'wardrobe-items'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'wardrobe-items'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );

create policy "wardrobe_items_delete_own" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'wardrobe-items'
    and (storage.foldername(name))[1] = (select auth.uid())::text
  );
