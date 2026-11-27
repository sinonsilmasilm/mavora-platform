# MAVORA payments and subscription integration

## Provider strategy
- Morocco-first: request a merchant proposal and recurring-payment eligibility from Payzone. Its public recurring-payments page says the solution is subject to eligibility conditions. Confirm contract, fees, settlement, refund/chargeback process, supported cards, recurring tokenization and webhook/API docs directly with Payzone before implementation.
- International: Paddle Billing is a candidate Merchant of Record. Morocco is not on Paddle's published unsupported supplier-country list, but onboarding approval is not guaranteed. Confirm your own seller account eligibility and payout route with Paddle.
- Paddle supports many buyer currencies but not every local currency; do not assume MAD checkout or MAD payout. Its published payout currencies do not include MAD. Confirm exact currency settings in your account. Morocco bank may receive USD/EUR with bank-side conversion/fees.
- Do not enable either provider in production until seller verification and legal/tax review are complete.

## Paddle Edge Functions in this repository
- `create-paddle-checkout`: authenticated store owner/admin only; uses server-side plan price IDs and creates a Paddle transaction.
- `paddle-webhook`: verifies Paddle-Signature HMAC, stores event IDs idempotently, updates subscription state.
- No Paddle account, product, price, API key, webhook secret, or seller approval has been supplied. These functions are scaffolding, not active payment processing.

## Required server-side secrets
- SUPABASE_URL
- SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY
- ALLOWED_ORIGIN
- PADDLE_API_KEY
- PADDLE_WEBHOOK_SECRET
- PADDLE_ENVIRONMENT=sandbox (until tested)
- PADDLE_PRICE_STARTER_MONTHLY
- PADDLE_PRICE_STARTER_ANNUAL
- PADDLE_PRICE_PRO_MONTHLY
- PADDLE_PRICE_PRO_ANNUAL
- PADDLE_PRICE_BUSINESS_MONTHLY
- PADDLE_PRICE_BUSINESS_ANNUAL

Never put API keys, webhook secrets or the Supabase service role key in GitHub Pages or browser code.

## Before production
- Create matching recurring products/prices in Paddle sandbox and map IDs above.
- Configure webhook endpoint for subscription.created, subscription.updated, subscription.canceled and transaction events needed for reconciliation.
- Test successful checkout, decline, duplicate webhook, out-of-order events, cancellation, renewal, past_due, refund and plan change.
- Verify Paddle subscription events preserve custom_data; if not, retrieve transaction/subscription metadata server-side.
- Add signed webhook retry handling, event replay tooling, payment reconciliation and invoice/tax display.
- Implement local Payzone adapter only from official merchant API docs supplied after onboarding.
- Current public plan_catalog records are deliberately is_sellable=false. Do not set true until full end-to-end tests pass.
