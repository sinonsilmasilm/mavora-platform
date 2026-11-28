-- MAVORA RLS and index optimization.
create index if not exists orders_customer_store_idx on public.orders(customer_id,store_id);
create index if not exists products_created_by_idx on public.products(created_by);

drop policy if exists "profile self read" on public.profiles;
create policy "profile self read" on public.profiles for select to authenticated using (id=(select auth.uid()));
drop policy if exists "profile self update" on public.profiles;
create policy "profile self update" on public.profiles for update to authenticated using (id=(select auth.uid())) with check (id=(select auth.uid()));
drop policy if exists "profile self insert" on public.profiles;
create policy "profile self insert" on public.profiles for insert to authenticated with check (id=(select auth.uid()));

drop policy if exists "stores owner create" on public.stores;
create policy "stores owner create" on public.stores for insert to authenticated with check (owner_user_id=(select auth.uid()));

drop policy if exists "ticket members create" on public.support_tickets;
create policy "ticket members create" on public.support_tickets for insert to authenticated
with check (public.has_store_role(store_id,array['owner','admin','staff']) and created_by=(select auth.uid()));

drop policy if exists "ticket members add messages" on public.support_messages;
create policy "ticket members add messages" on public.support_messages for insert to authenticated
with check (public.has_store_role(store_id,array['owner','admin','staff']) and author_user_id=(select auth.uid()) and author_type='merchant');
