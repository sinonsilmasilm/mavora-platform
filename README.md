# MAVORA

MAVORA is a Morocco-first store-management SaaS project for electronics and mobile-accessory retailers.

## Public website
- `index.html`: product overview and proposed pricing (not open for sale).
- `app.html`: local browser-only demo dashboard.
- `help.html`: self-service help and current service limitations.
- `privacy.html` / `terms.html`: notices for the demo only.

## Current public release
The dashboard stores products and demo orders in browser localStorage. It is not a production SaaS. There is no deployed authentication, cloud database, live AI assistant, WhatsApp integration, subscription checkout, staffed support inbox, or automatic cloud backup. Do not collect real customer data or accept payments.

## Backend foundation — code only, not deployed
- `supabase/migrations/202611270001_initial_schema.sql`: initial multi-tenant schema and RLS policies.
- `supabase/migrations/202611270002_commercial_operations.sql`: plans, support tickets, billing event ledger, AI usage quotas and backup metadata.
- `supabase/functions/store-assistant/`: catalog-grounded AI assistant with subscription and monthly quota checks.
- `supabase/functions/create-paddle-checkout/`: server-side Paddle checkout scaffold.
- `supabase/functions/paddle-webhook/`: signed Paddle webhook scaffold.
- `supabase/functions/create-support-ticket/`: authenticated support ticket creation endpoint.
- `supabase/config.toml`: JWT verification settings; Paddle webhook is configured without Supabase JWT and verifies Paddle signature itself.
- `supabase/.env.example`: names of required secrets; contains no real credentials.

None of the migrations or Edge Functions has been deployed to a Supabase project. A project, secrets, recurring price IDs, provider approval, frontend authentication, merchant-facing cloud dashboard, support-agent inbox, automated backup jobs, security tests and restore drills are still required.

## Proposed Morocco pricing
See `docs/PRICING_DECISION.md`. Suggested launch prices: 79 / 149 / 299 MAD monthly, with annual pricing at 10 months. These are hypotheses, not active offers. Setup is scoped separately. AI usage and WhatsApp fees must be capped/passed through.

## Payments, support and backups
See:
- `docs/PAYMENTS_AND_SUBSCRIPTIONS.md`
- `docs/ACCOUNT_SUPPORT_BACKUPS.md`
- `docs/COMMERCIAL_LAUNCH_CHECKLIST.md`

Paddle is a candidate for international SaaS billing after seller approval. For Moroccan MAD subscriptions, Payzone recurring payments is a candidate subject to merchant eligibility and a signed agreement. Do not expose private keys in GitHub Pages or browser JavaScript.

## Hosting
GitHub Pages serves static public pages only. It cannot run the backend or safely hold private API keys.