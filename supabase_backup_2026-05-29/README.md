# Supabase Backup — 2026-05-29

Project URL: https://kezcsrprvhzysftopjqd.supabase.co

This backup captures the LMS Supabase project as of 2026-05-29.

## Contents

- `schema.sql` — Full DDL for the `public` schema: enums, tables, constraints,
  indexes, functions, triggers, RLS policies, role grants. Idempotent where
  practical (uses `if not exists` / `or replace`). Excludes auth/storage
  internals managed by Supabase.
- `data/*.json` — Row-level data dumps per table (JSON, preserves nulls/types).
- `data/auth_users.json` — Snapshot of `auth.users` (subset of columns: ids,
  emails, metadata, timestamps). Note: password hashes are NOT included.
  Restoring auth users requires either re-inviting users or admin-API import.
- `data/storage_objects.json` — Metadata for `storage.objects` (object bodies
  live in Supabase Storage and are NOT included in this backup — see
  "Storage objects" below to fetch the binaries).
- `migrations.json` — `supabase_migrations.schema_migrations` contents
  (version, name, statements).
- `storage_buckets.json` — Storage bucket configuration.
- `edge_functions.json` — Edge function list (project has none).
- `restore.md` — Restore notes / order of operations.

## What is NOT included

- Object bodies for files in storage bucket `loan_documents` (12 objects,
  ~22 MB total). Use the Supabase CLI or Storage API with the service-role
  key to download:
  ```
  supabase storage download --recursive ss:///loan_documents ./loan_documents_files
  ```
- `auth.users` password hashes, MFA factors, sessions, refresh tokens,
  identities — these require a Postgres-level dump (`pg_dump`) against the
  database directly, which this MCP-based backup cannot perform.
- Any non-`public` user schemas (none exist).

For a truly complete byte-level backup, also run:
```
supabase db dump --db-url "$SUPABASE_DB_URL" -f full_pg_dump.sql
```
against the project's pooler connection string.
