# MAVORA backend foundation

This repository now includes a draft Supabase/Postgres multi-tenant schema and a server-side catalog assistant function.

## Not deployed
These files are scaffolding only. No Supabase project has been created or connected, and no production credentials have been supplied. The SQL has not been executed against a database. Do not treat the feature as live.

## Database
Review and apply `supabase/migrations/202611270001_initial_schema.sql` to a fresh Supabase project. It creates store membership, products, inventory movements, customers, orders, order items, subscriptions, audit logs, row-level security policies, and a private product-image bucket.

Before production, add automated tests proving that a user from Store A cannot read or write Store B data. Review all policies and indexes with a database engineer. This migration is a starting point, not a security certification.

## Catalog assistant Edge Function
Deploy `supabase/functions/store-assistant/index.ts` as a Supabase Edge Function. Configure server-side secrets:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `OPENAI_API_KEY`
- `OPENAI_MODEL`
- `ALLOWED_ORIGIN` (the exact production app origin)

Never put the service role key or OpenAI key in browser JavaScript or GitHub Pages. Configure a production origin allowlist, rate limiting, usage caps, logging redaction, and abuse monitoring before enabling this endpoint.

## Next engineering work
- Build frontend authentication and store onboarding against Supabase Auth.
- Replace localStorage data operations with tenant-scoped database operations.
- Implement transactional order creation and inventory movements (prefer Postgres RPC/transactions).
- Add invitations and secure membership management.
- Add webhook-backed subscriptions and payment state machine.
- Add Meta WhatsApp OAuth/onboarding, webhook signature verification, templates, opt-in/opt-out and human handoff.
- Add privacy/data export/deletion workflows and operational monitoring.
