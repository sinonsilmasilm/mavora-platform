# MAVORA

MAVORA is a Morocco-first store-management SaaS project for electronics and mobile-accessory retailers.

## Public pages
- `index.html`: public product/marketing page. Prices and roadmap features are explicitly marked as proposed or not yet available.
- `app.html`: local browser-only demo dashboard.
- `privacy.html`: privacy notice for the current demo only.
- `terms.html`: demo-use terms, not final commercial terms.

## Current demo status
The dashboard stores products and demo orders in browser localStorage. It is not a production SaaS application. There is no deployed authentication, cloud database, multi-tenant data isolation, real AI assistant, WhatsApp integration, subscription billing, or customer support operation. Do not collect real customer data or accept payments.

## Backend foundation (not deployed)
- `supabase/migrations/202611270001_initial_schema.sql`: draft Postgres schema with store membership and RLS policies.
- `supabase/functions/store-assistant/index.ts`: draft server-side catalog assistant.
- `supabase/README.md`: deployment prerequisites and required secrets.

These files have not been applied or deployed. A Supabase project, server-side secrets, tests, and security review are still required.

## Commercial launch
See `docs/COMMERCIAL_LAUNCH_CHECKLIST.md` for product, security, payments, WhatsApp, privacy, legal and sales requirements.

## Hosting
GitHub Pages serves the static public pages only. It cannot run the backend or safely hold private API keys.