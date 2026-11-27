# MAVORA — Commercial launch checklist

Status: planning document, not proof of compliance or production readiness.

## Product and customer experience
- [ ] Public marketing site with honest feature status and pricing marked as proposed.
- [ ] Merchant onboarding and store profile.
- [ ] Multi-tenant authentication, invitations, role permissions, password recovery, MFA option.
- [ ] Product catalog: SKU, barcode, category, variants, cost, selling price, tax, images, CSV import/export.
- [ ] Inventory: stock movements, low-stock alerts, adjustments, audit trail.
- [ ] Orders: customer details, line items, delivery address, order status, cancellation/return, printable invoice/packing slip.
- [ ] Customer CRM: consent, contact preferences, order history, export/delete workflow.
- [ ] Reports: revenue, order count, best sellers, gross margin, inventory valuation; define refund/tax accounting.
- [ ] Arabic RTL and French UI; later English and localized currencies.
- [ ] Accessible mobile UX, loading/error/empty states, help center, support workflow.
- [ ] Data export, restore, retention, account deletion, incident response.

## Backend and security
- [ ] Deploy managed backend and production database.
- [ ] Enforce tenant isolation with row-level security and server-side authorization.
- [ ] Keep all service-role/API secrets on server; never in frontend or Git.
- [ ] Rate limiting, input validation, CSRF/CORS strategy, secure headers, logging and monitoring.
- [ ] Automated unit, integration, authorization and cross-tenant isolation tests.
- [ ] Database migrations, backups, restore drills and retention policy.
- [ ] Storage policies for product images; file type/size validation and malware controls.
- [ ] Separate development, staging and production environments.

## AI and WhatsApp
- [ ] AI responses grounded only in the merchant's catalog and store policies.
- [ ] Low-confidence fallback to human; no invented prices, stock or delivery promises.
- [ ] Prompt-injection defenses, abuse/rate limits, cost limits, conversation retention controls.
- [ ] Merchant-owned Meta Business Portfolio, WhatsApp Business Account and phone number.
- [ ] Meta app, webhook verification, approved templates where required, opt-in and opt-out handling.
- [ ] Human handoff and message audit trail.

## Payments and subscriptions
- [ ] Choose provider only after merchant eligibility, recurring billing, settlement currency, fees, refunds and chargebacks are confirmed in writing.
- [ ] Server-side checkout/session creation and signed webhook verification.
- [ ] Subscription states, trials, grace period, cancellation, failed-payment retry, invoices and tax handling.
- [ ] Never store raw card data.
- [ ] Test cards/sandbox, refunds, duplicate webhook delivery and reconciliation.

## Morocco legal and operational
- [ ] Confirm legal form, commercial activity classification, invoicing and tax obligations with a Moroccan accountant/lawyer.
- [ ] Confirm CNDP notification/authorization and cross-border transfer requirements before processing personal data.
- [ ] Publish final privacy notice, terms, cookie notice if applicable, DPA/subprocessor list and retention schedule.
- [ ] Confirm brand availability and file trademark only after prior-rights search at OMPIC and relevant international databases.
- [ ] Publish real legal business identity, support email/address, complaint and cancellation process.
- [ ] Check consumer, e-commerce, electronic contracting and tax requirements for each market.

## Sales and operations
- [ ] Interview 10 merchants; pilot with 5; convert at least 3 to paid pilots before scaling ads.
- [ ] Measure activation, weekly active stores, orders managed, support time saved, churn and gross margin.
- [ ] Prepare demo data, onboarding checklist, product import template, training video and support FAQ.
- [ ] Prepare transparent pricing, setup scope, service-level boundaries and refund/cancellation terms.
- [ ] Define support hours, incident contact and status page.
- [ ] Unit economics: hosting, database, AI tokens, WhatsApp conversations, payment fees, support and onboarding labor.

## Current release truth
The current GitHub Pages deployment is a static local prototype. Browser localStorage is device/browser-specific. There is no production authentication, cloud database, tenant isolation, real AI, WhatsApp integration, payment processing, or commercial support. Do not accept customer data or subscription payments until the relevant checks above are completed.