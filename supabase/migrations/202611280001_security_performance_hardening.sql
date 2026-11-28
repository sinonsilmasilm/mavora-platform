-- MAVORA security and performance hardening.
-- Safe additive migration; no tenant data is deleted.
revoke all on function public.add_store_owner() from public, anon, authenticated;
revoke all on function public.rls_auto_enable() from public, anon, authenticated;
revoke all on function public.is_store_member(uuid) from public, anon;
revoke all on function public.has_store_role(uuid,text[]) from public, anon;
grant execute on function public.is_store_member(uuid) to authenticated;
grant execute on function public.has_store_role(uuid,text[]) to authenticated;
revoke all on function public.consume_ai_reply(uuid,integer) from public, anon, authenticated;
grant execute on function public.consume_ai_reply(uuid,integer) to service_role;

-- Billing events, plan writes, subscription writes and backup writes are service-role only.
-- billing_events intentionally has RLS enabled and no browser-facing policies.

-- Cover common tenant joins and foreign-key lookups.
create index if not exists stores_owner_user_id_idx on public.stores(owner_user_id);
create index if not exists store_members_user_id_idx on public.store_members(user_id);
create index if not exists inventory_movements_product_id_idx on public.inventory_movements(product_id);
create index if not exists inventory_movements_actor_user_id_idx on public.inventory_movements(actor_user_id);
create index if not exists orders_created_by_idx on public.orders(created_by);
create index if not exists order_items_order_store_idx on public.order_items(order_id,store_id);
create index if not exists order_items_product_store_idx on public.order_items(product_id,store_id);
create index if not exists order_items_store_id_idx on public.order_items(store_id);
create index if not exists audit_logs_actor_user_id_idx on public.audit_logs(actor_user_id);
create index if not exists support_messages_store_id_idx on public.support_messages(store_id);
create index if not exists support_messages_author_user_id_idx on public.support_messages(author_user_id);
create index if not exists support_tickets_created_by_idx on public.support_tickets(created_by);
create index if not exists backup_runs_store_id_idx on public.backup_runs(store_id);
create index if not exists billing_events_store_id_idx on public.billing_events(store_id);

-- Split the combined membership policy into action-specific policies.
drop policy if exists "owner manages members" on public.store_members;
create policy "owner inserts members" on public.store_members for insert to authenticated
with check (public.has_store_role(store_id,array['owner']));
create policy "owner updates members" on public.store_members for update to authenticated
using (public.has_store_role(store_id,array['owner']))
with check (public.has_store_role(store_id,array['owner']));
create policy "owner deletes members" on public.store_members for delete to authenticated
using (public.has_store_role(store_id,array['owner']));
