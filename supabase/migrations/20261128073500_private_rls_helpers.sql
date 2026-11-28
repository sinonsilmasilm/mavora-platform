-- Move SECURITY DEFINER helpers out of the exposed public API schema.
-- Existing RLS policy dependencies remain attached to the same function OIDs.
create schema if not exists private;
revoke all on schema private from public;
revoke all on schema private from anon;
grant usage on schema private to authenticated;

alter function public.has_store_role(uuid, text[]) set schema private;
alter function public.is_store_member(uuid) set schema private;

revoke all on function private.has_store_role(uuid, text[]) from public, anon;
revoke all on function private.is_store_member(uuid) from public, anon;
grant execute on function private.has_store_role(uuid, text[]) to authenticated;
grant execute on function private.is_store_member(uuid) to authenticated;
