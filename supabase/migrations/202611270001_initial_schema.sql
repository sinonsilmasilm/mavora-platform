-- MAVORA multi-tenant foundation. Review and apply only in a new Supabase project.
create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references auth.users(id) on delete restrict,
  name text not null check (char_length(name) between 2 and 120),
  slug text not null unique check (slug ~ '^[a-z0-9][a-z0-9-]{1,48}[a-z0-9]$'),
  country_code text not null default 'MA' check (country_code ~ '^[A-Z]{2}$'),
  currency_code text not null default 'MAD' check (currency_code ~ '^[A-Z]{3}$'),
  timezone text not null default 'Africa/Casablanca',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.store_members (
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'staff' check (role in ('owner','admin','staff')),
  created_at timestamptz not null default now(),
  primary key (store_id,user_id)
);

create or replace function public.is_store_member(target_store uuid)
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.store_members m where m.store_id=target_store and m.user_id=auth.uid()) $$;

create or replace function public.has_store_role(target_store uuid, allowed_roles text[])
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.store_members m where m.store_id=target_store and m.user_id=auth.uid() and m.role=any(allowed_roles)) $$;

create or replace function public.add_store_owner()
returns trigger language plpgsql security definer set search_path = public
as $$ begin
  insert into public.store_members(store_id,user_id,role) values(new.id,new.owner_user_id,'owner')
  on conflict (store_id,user_id) do nothing;
  return new;
end $$;

drop trigger if exists trg_add_store_owner on public.stores;
create trigger trg_add_store_owner after insert on public.stores
for each row execute function public.add_store_owner();

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  sku text,
  barcode text,
  name text not null check (char_length(name) between 1 and 180),
  description text not null default '',
  category text,
  cost_price numeric(12,2) not null default 0 check (cost_price >= 0),
  sale_price numeric(12,2) not null default 0 check (sale_price >= 0),
  currency_code text not null default 'MAD' check (currency_code ~ '^[A-Z]{3}$'),
  stock_quantity integer not null default 0 check (stock_quantity >= 0),
  low_stock_threshold integer not null default 3 check (low_stock_threshold >= 0),
  image_path text,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(store_id,sku),
  unique(store_id,barcode)
);
create index if not exists products_store_name_idx on public.products(store_id,name);
create index if not exists products_store_active_idx on public.products(store_id,is_active);

create table if not exists public.inventory_movements (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  movement_type text not null check (movement_type in ('opening','purchase','sale','return','adjustment','damage')),
  quantity_delta integer not null check (quantity_delta <> 0),
  note text,
  actor_user_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists inventory_store_created_idx on public.inventory_movements(store_id,created_at desc);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  full_name text not null check (char_length(full_name) between 1 and 160),
  phone text,
  email text,
  address text,
  marketing_opt_in boolean not null default false,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists customers_store_name_idx on public.customers(store_id,full_name);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  customer_id uuid references public.customers(id) on delete set null,
  order_number text not null,
  status text not null default 'pending' check (status in ('pending','confirmed','processing','shipped','delivered','cancelled','returned')),
  currency_code text not null default 'MAD' check (currency_code ~ '^[A-Z]{3}$'),
  subtotal numeric(12,2) not null default 0 check (subtotal >= 0),
  discount_total numeric(12,2) not null default 0 check (discount_total >= 0),
  shipping_total numeric(12,2) not null default 0 check (shipping_total >= 0),
  total numeric(12,2) not null default 0 check (total >= 0),
  shipping_address jsonb not null default '{}'::jsonb,
  customer_note text,
  internal_note text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(store_id,order_number)
);
create index if not exists orders_store_created_idx on public.orders(store_id,created_at desc);
create index if not exists orders_store_status_idx on public.orders(store_id,status);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name_snapshot text not null,
  sku_snapshot text,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null check (unit_price >= 0),
  line_total numeric(12,2) not null check (line_total >= 0),
  created_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null unique references public.stores(id) on delete cascade,
  provider text,
  provider_customer_id text,
  provider_subscription_id text,
  plan_code text not null default 'trial',
  status text not null default 'inactive' check (status in ('trialing','active','past_due','cancelled','inactive')),
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists audit_store_created_idx on public.audit_logs(store_id,created_at desc);

alter table public.profiles enable row level security;
alter table public.stores enable row level security;
alter table public.store_members enable row level security;
alter table public.products enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.customers enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.subscriptions enable row level security;
alter table public.audit_logs enable row level security;

drop policy if exists "profile self read" on public.profiles;
create policy "profile self read" on public.profiles for select to authenticated using (id=auth.uid());
drop policy if exists "profile self update" on public.profiles;
create policy "profile self update" on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());
drop policy if exists "profile self insert" on public.profiles;
create policy "profile self insert" on public.profiles for insert to authenticated with check (id=auth.uid());

drop policy if exists "stores member read" on public.stores;
create policy "stores member read" on public.stores for select to authenticated using (public.is_store_member(id));
drop policy if exists "stores owner create" on public.stores;
create policy "stores owner create" on public.stores for insert to authenticated with check (owner_user_id=auth.uid());
drop policy if exists "stores admin update" on public.stores;
create policy "stores admin update" on public.stores for update to authenticated using (public.has_store_role(id,array['owner','admin'])) with check (public.has_store_role(id,array['owner','admin']));
drop policy if exists "stores owner delete" on public.stores;
create policy "stores owner delete" on public.stores for delete to authenticated using (public.has_store_role(id,array['owner']));

drop policy if exists "members read same store" on public.store_members;
create policy "members read same store" on public.store_members for select to authenticated using (public.is_store_member(store_id));
drop policy if exists "owner manages members" on public.store_members;
create policy "owner manages members" on public.store_members for all to authenticated using (public.has_store_role(store_id,array['owner'])) with check (public.has_store_role(store_id,array['owner']));

drop policy if exists "products member read" on public.products;
create policy "products member read" on public.products for select to authenticated using (public.is_store_member(store_id));
drop policy if exists "products staff write" on public.products;
create policy "products staff write" on public.products for insert to authenticated with check (public.has_store_role(store_id,array['owner','admin','staff']));
drop policy if exists "products staff update" on public.products;
create policy "products staff update" on public.products for update to authenticated using (public.has_store_role(store_id,array['owner','admin','staff'])) with check (public.has_store_role(store_id,array['owner','admin','staff']));
drop policy if exists "products admin delete" on public.products;
create policy "products admin delete" on public.products for delete to authenticated using (public.has_store_role(store_id,array['owner','admin']));

drop policy if exists "inventory member read" on public.inventory_movements;
create policy "inventory member read" on public.inventory_movements for select to authenticated using (public.is_store_member(store_id));
drop policy if exists "inventory staff insert" on public.inventory_movements;
create policy "inventory staff insert" on public.inventory_movements for insert to authenticated with check (public.has_store_role(store_id,array['owner','admin','staff']));

drop policy if exists "customers member read" on public.customers;
create policy "customers member read" on public.customers for select to authenticated using (public.is_store_member(store_id));
drop policy if exists "customers staff insert" on public.customers;
create policy "customers staff insert" on public.customers for insert to authenticated with check (public.has_store_role(store_id,array['owner','admin','staff']));
drop policy if exists "customers staff update" on public.customers;
create policy "customers staff update" on public.customers for update to authenticated using (public.has_store_role(store_id,array['owner','admin','staff'])) with check (public.has_store_role(store_id,array['owner','admin','staff']));
drop policy if exists "customers admin delete" on public.customers;
create policy "customers admin delete" on public.customers for delete to authenticated using (public.has_store_role(store_id,array['owner','admin']));

drop policy if exists "orders member read" on public.orders;
create policy "orders member read" on public.orders for select to authenticated using (public.is_store_member(store_id));
drop policy if exists "orders staff insert" on public.orders;
create policy "orders staff insert" on public.orders for insert to authenticated with check (public.has_store_role(store_id,array['owner','admin','staff']));
drop policy if exists "orders staff update" on public.orders;
create policy "orders staff update" on public.orders for update to authenticated using (public.has_store_role(store_id,array['owner','admin','staff'])) with check (public.has_store_role(store_id,array['owner','admin','staff']));
drop policy if exists "orders admin delete" on public.orders;
create policy "orders admin delete" on public.orders for delete to authenticated using (public.has_store_role(store_id,array['owner','admin']));

drop policy if exists "order items member read" on public.order_items;
create policy "order items member read" on public.order_items for select to authenticated using (public.is_store_member(store_id));
drop policy if exists "order items staff insert" on public.order_items;
create policy "order items staff insert" on public.order_items for insert to authenticated with check (public.has_store_role(store_id,array['owner','admin','staff']));
drop policy if exists "order items staff update" on public.order_items;
create policy "order items staff update" on public.order_items for update to authenticated using (public.has_store_role(store_id,array['owner','admin','staff'])) with check (public.has_store_role(store_id,array['owner','admin','staff']));
drop policy if exists "order items admin delete" on public.order_items;
create policy "order items admin delete" on public.order_items for delete to authenticated using (public.has_store_role(store_id,array['owner','admin']));

drop policy if exists "subscription owner read" on public.subscriptions;
create policy "subscription owner read" on public.subscriptions for select to authenticated using (public.has_store_role(store_id,array['owner']));
drop policy if exists "audit admins read" on public.audit_logs;
create policy "audit admins read" on public.audit_logs for select to authenticated using (public.has_store_role(store_id,array['owner','admin']));

-- Private product image bucket. Object paths must start with the store UUID.
insert into storage.buckets(id,name,public) values('mavora-product-images','mavora-product-images',false)
on conflict (id) do nothing;
drop policy if exists "store members read product images" on storage.objects;
create policy "store members read product images" on storage.objects for select to authenticated
using (bucket_id='mavora-product-images' and public.is_store_member((storage.foldername(name))[1]::uuid));
drop policy if exists "store members upload product images" on storage.objects;
create policy "store members upload product images" on storage.objects for insert to authenticated
with check (bucket_id='mavora-product-images' and public.has_store_role((storage.foldername(name))[1]::uuid,array['owner','admin','staff']));
drop policy if exists "store admins delete product images" on storage.objects;
create policy "store admins delete product images" on storage.objects for delete to authenticated
using (bucket_id='mavora-product-images' and public.has_store_role((storage.foldername(name))[1]::uuid,array['owner','admin']));

grant execute on function public.is_store_member(uuid) to authenticated;
grant execute on function public.has_store_role(uuid,text[]) to authenticated;
