-- Pin search_path on the updated_at trigger function (advisor 0011).
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- handle_new_user is only ever invoked by the on_auth_user_created trigger.
-- Triggers run as the table owner, so they do not need EXECUTE granted to the
-- caller. Revoking it stops anon/authenticated calling it as an RPC (advisor 0028/0029).
revoke execute on function public.handle_new_user() from public;
revoke execute on function public.handle_new_user() from anon;
revoke execute on function public.handle_new_user() from authenticated;
