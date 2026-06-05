# Demo Setup Script Design

## 1. Overview
A suite of Node.js scripts using the `@supabase/supabase-js` client (with Service Role privileges) to back up the current database state, wipe all data, and seed a comprehensive demonstration dataset. This ensures a clean, predictable state for showcasing the complete workflow of the Loan Management System.

## 2. Architecture & Execution Flow
The scripts will be placed in `lms-backend/src/scripts/demo-setup/`.
1. **`backup.ts`**: Connects via `service_role` key and fetches all rows from `users`, `staff_profiles`, `loan_products`, `loan_applications`, `application_events`, `documents`, `loans`, and `emis`. Saves the JSON payload locally to `backups/data_state_<timestamp>.json`.
2. **`truncate.ts`**: Deletes all data. Clears `auth.users` using `auth.admin.deleteUser()` to trigger cascade deletion on the public `users` table, and then clears remaining tables in reverse-dependency order (`emis` -> `loans` -> `application_events` -> `documents` -> `loan_applications` -> `staff_profiles` -> `loan_products`).
3. **`seed.ts`**: Uses `auth.admin.createUser()` to auto-confirm users with a known password. Dynamically generates dates relative to the current execution time to ensure >30 and <30 days overdue EMIs are always accurate.
4. **`run-all.ts`**: An orchestrator script that runs the above sequentially.

## 3. Data Entities & Distribution

### Users & Roles (16 Users Total)
All users will share the same password (e.g., `Password123!`).
- **Admin (1)**: `admin@demo.com`
- **Manager (1)**: `manager@demo.com`
- **Loan Officers (4)**:
  - `lo_demo@demo.com` (Primary demonstration account).
  - `lo_active@demo.com` (Secondary account with active applications).
  - `lo_3@demo.com`, `lo_4@demo.com` (For manager's hierarchy view).
- **Borrowers (10)**:
  - `borrower_new@demo.com`: No applications. Used to demonstrate the full application flow.
  - `borrower_1@demo.com` to `borrower_5@demo.com`: Assigned to `lo_demo@demo.com`.
  - `borrower_6@demo.com` to `borrower_9@demo.com`: Assigned to `lo_active@demo.com`.

### Application & Workflow Scenarios
For the 5 borrowers assigned to `lo_demo@demo.com`:
- **Borrower 1**: Application `approved` -> Loan `disbursed` -> Status `active` -> 1 EMI overdue **> 30 days**.
- **Borrower 2**: Application `approved` -> Loan `disbursed` -> Status `active` -> 1 EMI overdue **< 30 days**.
- **Borrower 3**: Application `pending_manager_approval` (Escalated to manager).
- **Borrower 4**: Application `document_pending` (Document missing).
- **Borrower 5**: Application `under_review`.

For the 4 borrowers assigned to `lo_active@demo.com`:
- A realistic mix of `rejected`, `submitted`, and `approved` states.

### Audit Logs
- Every simulated state will include auto-generated rows in the `application_events` table mapping the timeline from `submitted` to the current state, complete with accurate historical timestamps.

## 4. Dependencies
- Supabase Project URL and Service Role Key (provided by user, to be read from process environment variables).
- `@supabase/supabase-js` package.
