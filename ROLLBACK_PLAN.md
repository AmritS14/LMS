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

## Tasks in progress
1. Manager review screen: replace hardcoded doc checklist with real application documents. (client-only)
2. Replace cosmetic fake numbers (avgDecisionTime, "14% faster", "+2.5% this week", seeded branchName) with real computed values. (client-only)
3. Manager "Send Back" persistence + Admin user management (edit role / deactivate / delete) — needs RLS policy changes.

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
