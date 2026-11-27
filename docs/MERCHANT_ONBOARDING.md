# MAVORA — Merchant onboarding playbook

This playbook is for supervised pilots only until cloud accounts and production controls are deployed.

## Before the session
- Confirm the merchant owns or is authorized to manage the store.
- Explain that the current public demo is local-only and must not contain real customer data.
- Agree the exact setup scope, product count, number of images, delivery, training time and one-time setup fee in writing.
- Collect product information through a merchant-approved secure channel. Do not request passwords, payment card details or customer lists.
- Use the import template in `docs/product-import-template.csv`.

## Product data required
Required: product name, selling price, quantity.
Recommended: SKU, barcode, category, product description, cost price, low-stock threshold, image URL or image file.
Validate duplicate SKUs, currency, decimal prices, negative stock, image rights and missing fields before import.

## Pilot workflow
1. Inventory the current product list and agree which products are in scope.
2. Clean product names, variants, prices and stock counts with the merchant.
3. Import demo/sample data only into the current local prototype.
4. Demonstrate product search, stock alerts and demo order flow.
5. Record missing workflows and defects.
6. Do not create real customer records or process real orders in the local prototype.
7. Collect structured feedback and permission before using any quote, logo or testimonial publicly.

## After cloud release
- Create the merchant's own account and store workspace.
- Verify the merchant's email and enable MFA where supported.
- Invite staff with least-privilege roles.
- Import products to the correct store tenant and verify counts.
- Configure store currency, timezone, tax/delivery settings and low-stock thresholds.
- Train owner and staff; provide a written quick-start guide.
- Confirm data export, account recovery and support contact.
- Obtain required privacy notices/consents before entering personal data.
- Sign the service agreement and activate a paid plan only after checkout and cancellation flows are tested.

## Completion criteria
The merchant can sign in from a second device, see only their store, add/update a product, record a stock movement, process a test order, export their data, invite an authorized staff member, and contact support. Until these pass in production, do not label onboarding as complete.