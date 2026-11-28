# MAVORA Supabase deployment

The repository now has a manual GitHub Actions deployment workflow at
`.github/workflows/deploy-supabase.yml`. It applies SQL migrations, configures
Edge Function secrets, and deploys the four Edge Functions. It does not create
a Supabase account or project.

## One-time GitHub Actions secrets

Add these under repository Settings → Secrets and variables → Actions → New repository secret:

Required to deploy the backend:
- `SUPABASE_ACCESS_TOKEN`: personal access token created in the Supabase dashboard.
- `SUPABASE_PROJECT_REF`: project reference of the target Supabase project.
- `SUPABASE_DB_PASSWORD`: database password chosen when creating that project.
- `SUPABASE_URL`: project URL, for example `https://PROJECT_REF.supabase.co`.
- `SUPABASE_ANON_KEY`: anon / publishable browser key.
- `SUPABASE_SERVICE_ROLE_KEY`: server-only service role key.

Optional AI secret (the AI assistant remains unavailable until configured):
- `OPENAI_API_KEY`
- `OPENAI_MODEL` (e.g. `gpt-4o-mini`)

Optional billing secrets (keep Paddle in sandbox until tested and approved):
- `PADDLE_API_KEY`
- `PADDLE_WEBHOOK_SECRET`
- `PADDLE_PRICE_STARTER_MONTHLY`
- `PADDLE_PRICE_STARTER_ANNUAL`
- `PADDLE_PRICE_PRO_MONTHLY`
- `PADDLE_PRICE_PRO_ANNUAL`
- `PADDLE_PRICE_BUSINESS_MONTHLY`
- `PADDLE_PRICE_BUSINESS_ANNUAL`

The frontend Pages workflow uses only `SUPABASE_URL` and
`SUPABASE_ANON_KEY`. These are public client credentials and are protected by
the database's Row Level Security policies. Never put the service role key,
database password, Supabase access token, OpenAI key, or Paddle secrets in
frontend files or commit them to Git.

## Deployment

After the required secrets are configured:
1. Open the repository's Actions tab.
2. Select **Deploy MAVORA Supabase backend**.
3. Choose **Run workflow** on the `main` branch.
4. Wait for all steps to succeed.
5. The push also starts the GitHub Pages workflow, which injects the public
   Supabase URL and anon key into the generated deployment artifact.

## Important

- The workflow is manual by design; it never creates or modifies a Supabase
  project automatically.
- Run it first against a new/staging project and inspect the SQL changes.
- Configure Paddle products, prices and webhook endpoint in Paddle sandbox
  before setting billing plans to sellable.
- The workflow sets Paddle environment to `sandbox`. Do not switch to production
  without seller approval, verified webhook delivery, successful test payments,
  refund/cancellation tests, and legal review.
- The database backup workflow remains separate and requires the backup secrets
  documented in `docs/ACCOUNT_SUPPORT_BACKUPS.md`. Test a restore before relying
  on backups.
