# MAVORA Supabase backend foundation

The repository contains database migrations and Edge Function scaffolding. Nothing has been deployed to a Supabase project yet.

## Deploy sequence
1. Create a Supabase project and keep the project reference, database password and API keys private.
2. Install Supabase CLI on a trusted computer (not inside the public website).
3. Link the project: `supabase link --project-ref YOUR_PROJECT_REF`.
4. Apply migrations: `supabase db push`. Review the SQL and test tenant isolation in a staging project first.
5. Configure server-side secrets from the values listed in `.env.example` using Supabase secrets. Never commit a real .env file.
6. Deploy the functions:
   - `supabase functions deploy store-assistant`
   - `supabase functions deploy create-paddle-checkout`
   - `supabase functions deploy paddle-webhook`
   - `supabase functions deploy create-support-ticket`
7. Configure Paddle sandbox products/prices and webhook destination, then set its API key, six recurring price IDs and notification endpoint secret. The webhook function has JWT verification disabled in `config.toml` because it validates Paddle's HMAC signature itself.
8. Run sandbox checkout and webhook simulations before changing the provider to production.
9. The new `cloud.html` / `cloud.js` frontend scaffold contains email signup/login/password reset, store creation, product CRUD, catalog assistant calls, support ticket creation, plan display, checkout invocation and store data export. It remains disabled until `supabase-client-config.js` is filled with the public project URL and anon/publishable key. The older `app.html` dashboard still uses localStorage.

## Required secrets
See `.env.example`. In addition, the scheduled encrypted database backup workflow needs GitHub Actions secrets documented in `docs/ACCOUNT_SUPPORT_BACKUPS.md`.

## Functions
- `store-assistant`: catalog-grounded AI answers. Requires active/trialing subscription and enforces monthly reply allowance using an atomic database RPC.
- `create-paddle-checkout`: store owner/admin only; refuses plans until `plan_catalog.is_sellable` is explicitly enabled.
- `paddle-webhook`: verifies Paddle HMAC signature over timestamp + raw request body, deduplicates event IDs, and ignores older subscription events.
- `create-support-ticket`: authenticated store members can create support tickets and their first message.

## Important gaps
- No Supabase project, secrets or Paddle account configuration is connected.
- No frontend signup/login/password-reset or cloud dashboard is deployed.
- No support-agent inbox, staff response UI, notifications or published support email exists.
- No Moroccan Payzone merchant API integration exists. Obtain official merchant documentation and eligibility before coding it.
- No WhatsApp integration exists.
- No automatic backup secrets or object-storage bucket have been configured; test restore before production.
- Security review, automated tests, monitoring, rate limiting and legal review remain mandatory.
