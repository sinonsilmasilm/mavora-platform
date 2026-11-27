# MAVORA account recovery, support and backups

## Account recovery
Production authentication is planned on Supabase Auth:
- email verification before account activation;
- password reset via one-time email link;
- session revocation and secure sign-out;
- MFA for owners/admins where enabled;
- least-privilege staff roles;
- account deletion and export workflow.
No live user accounts are configured yet. Do not claim account recovery works until the frontend Auth screens and email templates are connected and tested.

## Support tickets
The database migration creates support_tickets and support_messages with store membership policies. The Edge Function create-support-ticket accepts an authenticated store member and creates a ticket. A support-agent inbox, assignment, email notifications, response SLA and status dashboard are still required before calling this a staffed support service.

## Backup layers
1. Production database: Supabase Pro or above provides daily automated backups (Pro: 7 days retention, Team: 14 days, Enterprise: up to 30 days).
2. Merchant export: build a per-store export of products, stock movements, customers, orders and settings, stored encrypted in private object storage and downloadable only by store owners.
3. Off-site backup: periodically copy encrypted database exports to a separate provider/account; do not store the only backup in the same Supabase project.
4. Restore drills: schedule monthly restore tests into a separate staging project and record result, checksum, duration and recovery point.
5. Account security: MFA, verified email, session controls, audit logs and least privilege.

Supabase Point-in-Time Recovery is an extra paid add-on and can be expensive (published 7-day PITR is approximately USD 100/month). It is not appropriate for the current low-budget MVP. Daily backups plus encrypted off-site exports and tested restore procedures are a more realistic first production baseline.

## Never do this
- Do not claim localStorage export is a cloud backup.
- Do not keep raw card numbers or CVV.
- Do not expose backup files through public GitHub Pages.
- Do not send service-role keys to the browser.
- Do not collect real customer personal data until privacy/legal requirements are met.
