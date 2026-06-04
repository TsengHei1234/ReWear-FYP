-- Auto-create a profiles row when a new auth user signs up.
-- SECURITY DEFINER so the trigger can write to public.profiles; empty
-- search_path + fully-qualified names per Supabase security guidance.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
