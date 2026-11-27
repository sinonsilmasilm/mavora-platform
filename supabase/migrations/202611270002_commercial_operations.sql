-- MAVORA commercial operations: billing ledger, support, AI metering and backup audit.
-- Apply after 202611270001_initial_schema.sql in the same Supabase project.

create table if not exists public.billing_events (
  id uuid primary key default gen_random_uuid(),
  provider text not null,
  provider_event_id text not null,
  event_type text not null,
  store_id uuid references public.stores(id) on delete set null,
  payload_safe jsonb not null default '{}'::jsonb,
  processed_at timestamptz,
  processing_error text,
  received_at timestamptz not null default now(),
  unique(provider,provider_event_id)
);
create index if not exists billing_events_unprocessed_idx on public.billing_events(received_at) where processed_at is null;

create table if not exists public.plan_catalog (
  plan_code text primary key,
  display_name text not null,
  currency_code text not null default 'MAD' check(currency_code ~ '^[A-Z]{3}$'),
  monthly_amount numeric(12,2) not null check(monthly_amount >= 0),
  annual_amount numeric(12,2) not null check(annual_amount >= 0),
  max_users integer not null check(max_users > 0),
  max_products integer not null check(max_products > 0),
  ai_replies_monthly integer not null default 0 check(ai_replies_monthly >= 0),
  is_public boolean not null default false,
  is_sellable boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.plan_catalog enable row level security;
drop policy if exists "public can read published plans" on public.plan_catalog;
create policy "public can read published plans" on public.plan_catalog
for select to anon,authenticated using (is_public=true);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  created_by uuid not null references auth.users(id) on delete restrict,
  subject text not null check(char_length(subject) between 4 and 180),
  category text not null default 'general' check(category in ('general','billing','technical','data','security','feature')),
  priority text not null default 'normal' check(priority in ('low','normal','high','urgent')),
  status text not null default 'open' check(status in ('open','waiting_customer','waiting_support','resolved','closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists support_tickets_store_updated_idx on public.support_tickets(store_id,updated_at desc);

create table if not exists public.support_messages (
  id uuid primary key default gen_random_uuid(),
  ticket_id uuid not null references public.support_tickets(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  author_user_id uuid references auth.users(id) on delete set null,
  author_type text not null default 'merchant' check(author_type in ('merchant','support','system')),
  message text not null check(char_length(message) between 1 and 10000),
  attachment_path text,
  created_at timestamptz not null default now()
);
create index if not exists support_messages_ticket_created_idx on public.support_messages(ticket_id,created_at);

create table if not exists public.ai_usage_daily (
  store_id uuid not null references public.stores(id) on delete cascade,
  usage_date date not null default (now() at time zone 'UTC')::date,
  request_count integer not null default 0 check(request_count >= 0),
  token_estimate bigint not null default 0 check(token_estimate >= 0),
  updated_at timestamptz not null default now(),
  primary key(store_id,usage_date)
);

create table if not exists public.backup_runs (
  id uuid primary key default gen_random_uuid(),
  store_id uuid references public.stores(id) on delete cascade,
  backup_type text not null check(backup_type in ('database_daily','store_export','restore_test')),
  status text not null check(status in ('started','completed','failed')),
  storage_reference text,
  byte_size bigint,
  checksum_sha256 text,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  error_summary text
);
create index if not exists backup_runs_created_idx on public.backup_runs(created_at desc);

alter table public.billing_events enable row level security;
alter table public.support_tickets enable row level security;
alter table public.support_messages enable row level security;
alter table public.ai_usage_daily enable row level security;
alter table public.backup_runs enable row level security;

drop policy if exists "ticket members read" on public.support_tickets;
create policy "ticket members read" on public.support_tickets for select to authenticated
using (public.is_store_member(store_id));
drop policy if exists "ticket members create" on public.support_tickets;
create policy "ticket members create" on public.support_tickets for insert to authenticated
with check (public.has_store_role(store_id,array['owner','admin','staff']) and created_by=auth.uid());
drop policy if exists "ticket members read messages" on public.support_messages;
create policy "ticket members read messages" on public.support_messages for select to authenticated
using (public.is_store_member(store_id));
drop policy if exists "ticket members add messages" on public.support_messages;
create policy "ticket members add messages" on public.support_messages for insert to authenticated
with check (public.has_store_role(store_id,array['owner','admin','staff']) and author_user_id=auth.uid() and author_type='merchant');
drop policy if exists "store owners read AI usage" on public.ai_usage_daily;
create policy "store owners read AI usage" on public.ai_usage_daily for select to authenticated
using (public.has_store_role(store_id,array['owner','admin']));
drop policy if exists "store owners read backup history" on public.backup_runs;
create policy "store owners read backup history" on public.backup_runs for select to authenticated
using (store_id is not null and public.has_store_role(store_id,array['owner']));
-- Billing events, plan writes, backup writes and subscription writes are service-role only.
