# Rollback Plan — Partial-Feature Work (started 2026-05-27)

Backup point: git tag `backup/working-state-2026-05-27` at commit `d629469`.

## How to fully revert everything
```bash
git reset --hard backup/working-state-2026-05-27
```
Then run the DB rollback SQL below for any migration that was applied.

## Verified-working state being preserved (do NOT regress)
- Auth + Sign Out (all roles)
- Borrower: submit application, upload requested docs
- Officer: see app + real linked docs, verify/reject docs, request docs, messaging thread
- Borrower⇄Officer messaging (ensureThread)
- Manager: review queue (RLS-scoped), approve/reject, disburse
- Admin: real user list & staff profiles, create staff, loan-product list & create
- **EMI repayment**: borrower pays via `POST /emis/{id}/pay` (RepaymentViewModel / RepaymentDashboardView / HomeDashboardView) — already wired.

## Tasks
1. [DONE] Manager review screen: real application documents instead of fixed checklist. (commit 25cbe27)
2. [DONE] Real avgDecisionTime + replaced "14% faster"/"+2.5%" with real metrics. (commit 6286873)
   - NOTE: branch *name* has no backend source (no `branches` table), left as seeded value.
3. [DONE] Manager "Send Back" persistence (commit e7e063e — no RLS change) +
   Admin user management edit-role / activate-deactivate (commit d6cf655 — adds
   admin_update_users_policy). "Delete" is now a soft deactivation, not hard delete.

## DB migrations applied (append each here with rollback SQL BEFORE applying)

- Name: `admin_update_users_policy` — applied 2026-05-27
- Purpose: Let admins persist role changes / activate-deactivate on OTHER users.
  Previously only "Users can update own profile" (auth.uid()=id) existed, so
  admin user-management was UI-only. Additive policy, scoped to has_role('admin').
- Rollback SQL:
  ```sql
  drop policy if exists "Admins update users" on public.users;
  ```

### Migration template
- Name: `<migration_name>` — applied <date>
- Purpose: ...
- Rollback SQL:
  ```sql
  -- exact statements to undo
  ```
